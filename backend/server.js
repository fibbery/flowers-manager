const express = require('express');
const cors = require('cors');
const sqlite3 = require('sqlite3').verbose();
const path = require('path');

const app = express();
const PORT = 3000;

// 中间件
app.use(cors());
app.use(express.json());

// 初始化数据库
const db = new sqlite3.Database(path.join(__dirname, 'flowers.db'), (err) => {
  if (err) {
    console.error('数据库连接失败:', err.message);
  } else {
    console.log('数据库连接成功');
  }
});

// 启用外键约束
db.run('PRAGMA foreign_keys = ON');

// 创建表
db.serialize(() => {
  // 花库表（存储所有花朵类型）
  db.run(`
    CREATE TABLE IF NOT EXISTS flower_library (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT UNIQUE NOT NULL,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    )
  `);

  db.run(`
    CREATE TABLE IF NOT EXISTS persons (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT UNIQUE NOT NULL,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    )
  `);

  db.run(`
    CREATE TABLE IF NOT EXISTS flowers (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      person_id INTEGER NOT NULL,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (person_id) REFERENCES persons(id) ON DELETE CASCADE
    )
  `);
});

// API 路由

// ==================== 花库管理 API ====================

// 获取所有花库
app.get('/api/flower-library', (req, res) => {
  db.all('SELECT * FROM flower_library ORDER BY name', [], (err, flowers) => {
    if (err) {
      return res.status(500).json({ error: err.message });
    }
    res.json(flowers);
  });
});

// 添加花到花库
app.post('/api/flower-library', (req, res) => {
  const { name } = req.body;
  
  if (!name || !name.trim()) {
    return res.status(400).json({ error: '花朵名称不能为空' });
  }
  
  db.run('INSERT INTO flower_library (name) VALUES (?)', [name.trim()], function(err) {
    if (err) {
      if (err.message.includes('UNIQUE constraint failed')) {
        return res.status(400).json({ error: '该花朵已存在于花库中' });
      }
      return res.status(500).json({ error: err.message });
    }
    
    res.status(201).json({
      id: this.lastID,
      name: name.trim()
    });
  });
});

// 删除花库中的花
app.delete('/api/flower-library/:id', (req, res) => {
  db.run('DELETE FROM flower_library WHERE id = ?', [req.params.id], function(err) {
    if (err) {
      return res.status(500).json({ error: err.message });
    }
    
    if (this.changes === 0) {
      return res.status(404).json({ error: '花朵不存在' });
    }
    
    res.json({ message: '删除成功' });
  });
});

// 更新花库中的花
app.put('/api/flower-library/:id', (req, res) => {
  const { name } = req.body;
  
  if (!name || !name.trim()) {
    return res.status(400).json({ error: '花朵名称不能为空' });
  }
  
  db.run('UPDATE flower_library SET name = ? WHERE id = ?', [name.trim(), req.params.id], function(err) {
    if (err) {
      if (err.message.includes('UNIQUE constraint failed')) {
        return res.status(400).json({ error: '该花朵名称已存在' });
      }
      return res.status(500).json({ error: err.message });
    }
    
    if (this.changes === 0) {
      return res.status(404).json({ error: '花朵不存在' });
    }
    
    res.json({
      id: parseInt(req.params.id),
      name: name.trim()
    });
  });
});

// ==================== 人员管理 API ====================

// 获取所有人员及其花朵
app.get('/api/persons', (req, res) => {
  db.all('SELECT * FROM persons ORDER BY name', [], (err, persons) => {
    if (err) {
      return res.status(500).json({ error: err.message });
    }
    
    db.all('SELECT * FROM flowers', [], (err, flowers) => {
      if (err) {
        return res.status(500).json({ error: err.message });
      }
      
      // 组织数据：将花朵按人员分组
      const result = persons.map(person => ({
        id: person.id,
        name: person.name,
        flowers: flowers
          .filter(flower => flower.person_id === person.id)
          .map(flower => ({ id: flower.id, name: flower.name }))
      }));
      
      res.json(result);
    });
  });
});

// 获取单个人员信息
app.get('/api/persons/:id', (req, res) => {
  db.get('SELECT * FROM persons WHERE id = ?', [req.params.id], (err, person) => {
    if (err) {
      return res.status(500).json({ error: err.message });
    }
    if (!person) {
      return res.status(404).json({ error: '人员不存在' });
    }
    
    db.all('SELECT * FROM flowers WHERE person_id = ?', [req.params.id], (err, flowers) => {
      if (err) {
        return res.status(500).json({ error: err.message });
      }
      
      res.json({
        id: person.id,
        name: person.name,
        flowers: flowers.map(f => ({ id: f.id, name: f.name }))
      });
    });
  });
});

// 添加人员
app.post('/api/persons', (req, res) => {
  const { name, flowers } = req.body;
  
  if (!name || !name.trim()) {
    return res.status(400).json({ error: '人员名称不能为空' });
  }
  
  // 使用事务确保数据一致性
  db.serialize(() => {
    db.run('BEGIN TRANSACTION');
    
    db.run('INSERT INTO persons (name) VALUES (?)', [name.trim()], function(err) {
      if (err) {
        db.run('ROLLBACK');
        if (err.message.includes('UNIQUE constraint failed')) {
          return res.status(400).json({ error: '该人员名称已存在' });
        }
        return res.status(500).json({ error: err.message });
      }
      
      const personId = this.lastID;
      
      // 插入花朵
      if (flowers && Array.isArray(flowers) && flowers.length > 0) {
        const validFlowers = flowers.filter(f => f.name && f.name.trim());
        let completed = 0;
        
        if (validFlowers.length === 0) {
          db.run('COMMIT');
          return getPersonAndRespond(personId, res, 201);
        }
        
        validFlowers.forEach((flower, index) => {
          db.run('INSERT INTO flowers (name, person_id) VALUES (?, ?)', 
            [flower.name.trim(), personId], 
            (err) => {
              if (err) {
                db.run('ROLLBACK');
                return res.status(500).json({ error: err.message });
              }
              
              completed++;
              if (completed === validFlowers.length) {
                db.run('COMMIT');
                getPersonAndRespond(personId, res, 201);
              }
            }
          );
        });
      } else {
        db.run('COMMIT');
        getPersonAndRespond(personId, res, 201);
      }
    });
  });
});

// 辅助函数：获取人员信息并返回
function getPersonAndRespond(personId, res, statusCode = 200) {
  db.get('SELECT * FROM persons WHERE id = ?', [personId], (err, person) => {
    if (err) {
      return res.status(500).json({ error: err.message });
    }
    
    db.all('SELECT * FROM flowers WHERE person_id = ?', [personId], (err, flowers) => {
      if (err) {
        return res.status(500).json({ error: err.message });
      }
      
      res.status(statusCode).json({
        id: person.id,
        name: person.name,
        flowers: flowers.map(f => ({ id: f.id, name: f.name }))
      });
    });
  });
}

// 更新人员
app.put('/api/persons/:id', (req, res) => {
  const { name, flowers } = req.body;
  const personId = req.params.id;
  
  if (!name || !name.trim()) {
    return res.status(400).json({ error: '人员名称不能为空' });
  }
  
  // 检查人员是否存在
  db.get('SELECT * FROM persons WHERE id = ?', [personId], (err, person) => {
    if (err) {
      return res.status(500).json({ error: err.message });
    }
    if (!person) {
      return res.status(404).json({ error: '人员不存在' });
    }
    
    // 使用事务更新
    db.serialize(() => {
      db.run('BEGIN TRANSACTION');
      
      // 更新人员名称
      db.run('UPDATE persons SET name = ? WHERE id = ?', [name.trim(), personId], (err) => {
        if (err) {
          db.run('ROLLBACK');
          if (err.message.includes('UNIQUE constraint failed')) {
            return res.status(400).json({ error: '该人员名称已存在' });
          }
          return res.status(500).json({ error: err.message });
        }
        
        // 删除旧的花朵
        db.run('DELETE FROM flowers WHERE person_id = ?', [personId], (err) => {
          if (err) {
            db.run('ROLLBACK');
            return res.status(500).json({ error: err.message });
          }
          
          // 插入新的花朵
          if (flowers && Array.isArray(flowers) && flowers.length > 0) {
            const validFlowers = flowers.filter(f => f.name && f.name.trim());
            
            if (validFlowers.length === 0) {
              db.run('COMMIT');
              return getPersonAndRespond(personId, res);
            }
            
            let completed = 0;
            validFlowers.forEach(flower => {
              db.run('INSERT INTO flowers (name, person_id) VALUES (?, ?)', 
                [flower.name.trim(), personId], 
                (err) => {
                  if (err) {
                    db.run('ROLLBACK');
                    return res.status(500).json({ error: err.message });
                  }
                  
                  completed++;
                  if (completed === validFlowers.length) {
                    db.run('COMMIT');
                    getPersonAndRespond(personId, res);
                  }
                }
              );
            });
          } else {
            db.run('COMMIT');
            getPersonAndRespond(personId, res);
          }
        });
      });
    });
  });
});

// 删除人员
app.delete('/api/persons/:id', (req, res) => {
  db.get('SELECT * FROM persons WHERE id = ?', [req.params.id], (err, person) => {
    if (err) {
      return res.status(500).json({ error: err.message });
    }
    if (!person) {
      return res.status(404).json({ error: '人员不存在' });
    }
    
    // 删除人员（由于外键约束，相关的花朵也会被删除）
    db.run('DELETE FROM persons WHERE id = ?', [req.params.id], (err) => {
      if (err) {
        return res.status(500).json({ error: err.message });
      }
      
      res.json({ message: '删除成功' });
    });
  });
});

// 查询 API

// 1. 根据人名查询该人有什么花
app.get('/api/search/person', (req, res) => {
  const { name } = req.query;
  
  if (!name || !name.trim()) {
    return res.status(400).json({ error: '请输入人员姓名' });
  }
  
  // 使用模糊查询
  db.all(
    'SELECT * FROM persons WHERE name LIKE ? ORDER BY name',
    [`%${name.trim()}%`],
    (err, persons) => {
      if (err) {
        return res.status(500).json({ error: err.message });
      }
      
      if (persons.length === 0) {
        return res.json({ results: [], message: '未找到匹配的人员' });
      }
      
      // 获取每个人的花朵
      let completed = 0;
      const results = [];
      
      persons.forEach(person => {
        db.all(
          'SELECT * FROM flowers WHERE person_id = ?',
          [person.id],
          (err, flowers) => {
            if (err) {
              return res.status(500).json({ error: err.message });
            }
            
            results.push({
              id: person.id,
              name: person.name,
              flowers: flowers.map(f => ({ id: f.id, name: f.name }))
            });
            
            completed++;
            if (completed === persons.length) {
              res.json({ results });
            }
          }
        );
      });
    }
  );
});

// 2. 根据花名查询拥有该花的人
app.get('/api/search/flower', (req, res) => {
  const { name } = req.query;
  
  if (!name || !name.trim()) {
    return res.status(400).json({ error: '请输入花朵名称' });
  }
  
  // 使用模糊查询
  db.all(
    'SELECT DISTINCT f.id, f.name, f.person_id FROM flowers f WHERE f.name LIKE ? ORDER BY f.name',
    [`%${name.trim()}%`],
    (err, flowers) => {
      if (err) {
        return res.status(500).json({ error: err.message });
      }
      
      if (flowers.length === 0) {
        return res.json({ results: [], message: '未找到匹配的花朵' });
      }
      
      // 获取拥有这些花朵的人员
      const personIds = [...new Set(flowers.map(f => f.person_id))];
      let completed = 0;
      const personsMap = new Map();
      
      personIds.forEach(personId => {
        db.get('SELECT * FROM persons WHERE id = ?', [personId], (err, person) => {
          if (err) {
            return res.status(500).json({ error: err.message });
          }
          
          if (person) {
            const personFlowers = flowers.filter(f => f.person_id === personId);
            personsMap.set(personId, {
              id: person.id,
              name: person.name,
              flowers: personFlowers.map(f => ({ id: f.id, name: f.name }))
            });
          }
          
          completed++;
          if (completed === personIds.length) {
            const results = Array.from(personsMap.values());
            res.json({ results });
          }
        });
      });
    }
  );
});

// 启动服务器
app.listen(PORT, () => {
  console.log(`服务器运行在 http://localhost:${PORT}`);
});

// 优雅关闭
process.on('SIGINT', () => {
  db.close();
  process.exit(0);
});

