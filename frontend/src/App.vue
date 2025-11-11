<template>
  <div class="container">
    <h1>🌸 花朵管理系统</h1>

    <!-- 错误提示 -->
    <div v-if="error" class="error">
      {{ error }}
    </div>

    <!-- 成功提示 -->
    <div v-if="success" class="success">
      {{ success }}
    </div>

    <!-- 查询区域 -->
    <div class="search-section">
      <h2>🔍 查询功能</h2>
      <div class="search-forms">
        <!-- 根据人名查询花朵 -->
        <div class="search-box">
          <h3>根据人名查花朵</h3>
          <div class="search-input-group">
            <input
              type="text"
              v-model="searchPersonName"
              placeholder="输入人名（支持模糊查询）"
              @keyup.enter="searchByPerson"
            />
            <button class="btn btn-primary" @click="searchByPerson">
              查询
            </button>
          </div>
        </div>

        <!-- 根据花名查询人 -->
        <div class="search-box">
          <h3>根据花名查拥有者</h3>
          <div class="search-input-group">
            <input
              type="text"
              v-model="searchFlowerName"
              placeholder="输入花名（支持模糊查询）"
              @keyup.enter="searchByFlower"
            />
            <button class="btn btn-primary" @click="searchByFlower">
              查询
            </button>
          </div>
        </div>
      </div>

      <!-- 查询结果 -->
      <div v-if="searchResults.length > 0" class="search-results">
        <div class="search-results-header">
          <h3>
            {{ searchMessage || '查询结果' }} 
            <span class="result-count">（共 {{ searchResults.length }} 条）</span>
          </h3>
          <button class="btn btn-secondary btn-small" @click="clearSearch">
            清除结果
          </button>
        </div>
        <div class="persons-grid">
          <div v-for="person in searchResults" :key="'search-' + person.id" class="person-card search-result-card">
            <div class="person-header">
              <h3 class="person-name">{{ person.name }}</h3>
            </div>
            <div class="flowers-section">
              <h4>拥有的花朵：</h4>
              <div v-if="person.flowers && person.flowers.length > 0" class="flowers-list">
                <span
                  v-for="flower in person.flowers"
                  :key="flower.id"
                  class="flower-tag"
                >
                  🌺 {{ flower.name }}
                </span>
              </div>
              <div v-else class="empty-flowers">
                暂无花朵
              </div>
            </div>
          </div>
        </div>
      </div>
      
      <div v-else-if="searchMessage" class="search-no-results">
        {{ searchMessage }}
      </div>
    </div>

    <!-- 添加/编辑表单 -->
    <div class="add-form">
      <h2>{{ isEditing ? '编辑人员' : '添加新人员' }}</h2>
      <form @submit.prevent="submitForm">
        <div class="form-group">
          <label for="personName">人员姓名 *</label>
          <input
            type="text"
            id="personName"
            v-model="form.name"
            placeholder="请输入人员姓名"
            required
          />
        </div>

        <div class="form-group">
          <label>花朵列表</label>
          <div v-for="(flower, index) in form.flowers" :key="index" class="flowers-input">
            <input
              type="text"
              v-model="flower.name"
              placeholder="请输入花朵名称"
            />
            <button
              type="button"
              class="btn btn-danger btn-small"
              @click="removeFlowerFromForm(index)"
            >
              删除
            </button>
          </div>
          <button
            type="button"
            class="btn btn-secondary btn-small"
            @click="addFlowerToForm"
          >
            + 添加花朵
          </button>
        </div>

        <div class="btn-group">
          <button type="submit" class="btn btn-success">
            {{ isEditing ? '更新' : '添加' }}
          </button>
          <button
            v-if="isEditing"
            type="button"
            class="btn btn-secondary"
            @click="cancelEdit"
          >
            取消
          </button>
        </div>
      </form>
    </div>

    <!-- 加载状态 -->
    <div v-if="loading" class="loading">
      加载中...
    </div>

    <!-- 人员列表 -->
    <div v-else-if="persons.length > 0" class="persons-grid">
      <div v-for="person in persons" :key="person.id" class="person-card">
        <div class="person-header">
          <h3 class="person-name">{{ person.name }}</h3>
          <div class="person-actions">
            <button
              class="btn btn-warning btn-small"
              @click="editPerson(person)"
            >
              编辑
            </button>
            <button
              class="btn btn-danger btn-small"
              @click="deletePerson(person.id, person.name)"
            >
              删除
            </button>
          </div>
        </div>

        <div class="flowers-section">
          <h4>拥有的花朵：</h4>
          <div v-if="person.flowers && person.flowers.length > 0" class="flowers-list">
            <span
              v-for="flower in person.flowers"
              :key="flower.id"
              class="flower-tag"
            >
              🌺 {{ flower.name }}
            </span>
          </div>
          <div v-else class="empty-flowers">
            暂无花朵
          </div>
        </div>
      </div>
    </div>

    <!-- 空状态 -->
    <div v-else class="empty-state">
      <div class="empty-state-icon">🌼</div>
      <p>还没有添加任何人员，点击上方表单开始添加吧！</p>
    </div>
  </div>
</template>

<script>
import { ref, onMounted } from 'vue'
import axios from 'axios'

export default {
  name: 'App',
  setup() {
    const persons = ref([])
    const loading = ref(false)
    const error = ref('')
    const success = ref('')
    const isEditing = ref(false)
    const editingId = ref(null)
    
    const form = ref({
      name: '',
      flowers: []
    })

    // 查询相关状态
    const searchPersonName = ref('')
    const searchFlowerName = ref('')
    const searchResults = ref([])
    const searchMessage = ref('')

    // API 基础 URL - 生产环境使用相对路径
    const API_BASE = process.env.NODE_ENV === 'production' ? '/api' : 'http://localhost:3000/api'

    // 清除提示信息
    const clearMessages = () => {
      error.value = ''
      success.value = ''
    }

    // 显示错误信息
    const showError = (message) => {
      error.value = message
      setTimeout(() => {
        error.value = ''
      }, 5000)
    }

    // 显示成功信息
    const showSuccess = (message) => {
      success.value = message
      setTimeout(() => {
        success.value = ''
      }, 3000)
    }

    // 获取所有人员
    const fetchPersons = async () => {
      loading.value = true
      clearMessages()
      try {
        const response = await axios.get(`${API_BASE}/persons`)
        persons.value = response.data
      } catch (err) {
        showError('获取数据失败: ' + (err.response?.data?.error || err.message))
      } finally {
        loading.value = false
      }
    }

    // 添加花朵到表单
    const addFlowerToForm = () => {
      form.value.flowers.push({ name: '' })
    }

    // 从表单移除花朵
    const removeFlowerFromForm = (index) => {
      form.value.flowers.splice(index, 1)
    }

    // 重置表单
    const resetForm = () => {
      form.value = {
        name: '',
        flowers: []
      }
      isEditing.value = false
      editingId.value = null
    }

    // 提交表单
    const submitForm = async () => {
      clearMessages()
      
      if (!form.value.name.trim()) {
        showError('请输入人员姓名')
        return
      }

      // 过滤掉空的花朵名称
      const validFlowers = form.value.flowers.filter(f => f.name.trim())

      try {
        if (isEditing.value) {
          // 更新
          await axios.put(`${API_BASE}/persons/${editingId.value}`, {
            name: form.value.name,
            flowers: validFlowers
          })
          showSuccess('更新成功！')
        } else {
          // 添加
          await axios.post(`${API_BASE}/persons`, {
            name: form.value.name,
            flowers: validFlowers
          })
          showSuccess('添加成功！')
        }
        
        resetForm()
        await fetchPersons()
      } catch (err) {
        showError(err.response?.data?.error || err.message)
      }
    }

    // 编辑人员
    const editPerson = (person) => {
      isEditing.value = true
      editingId.value = person.id
      form.value = {
        name: person.name,
        flowers: person.flowers.map(f => ({ name: f.name }))
      }
      
      // 滚动到表单
      window.scrollTo({ top: 0, behavior: 'smooth' })
    }

    // 取消编辑
    const cancelEdit = () => {
      resetForm()
    }

    // 删除人员
    const deletePerson = async (id, name) => {
      if (!confirm(`确定要删除 "${name}" 及其所有花朵吗？`)) {
        return
      }

      clearMessages()
      try {
        await axios.delete(`${API_BASE}/persons/${id}`)
        showSuccess('删除成功！')
        await fetchPersons()
      } catch (err) {
        showError(err.response?.data?.error || err.message)
      }
    }

    // 根据人名查询花朵
    const searchByPerson = async () => {
      if (!searchPersonName.value.trim()) {
        showError('请输入人员姓名')
        return
      }

      clearMessages()
      loading.value = true
      searchResults.value = []
      searchMessage.value = ''

      try {
        const response = await axios.get(`${API_BASE}/search/person`, {
          params: { name: searchPersonName.value }
        })
        
        if (response.data.results && response.data.results.length > 0) {
          searchResults.value = response.data.results
          searchMessage.value = `找到 ${response.data.results.length} 个匹配的人员`
        } else {
          searchMessage.value = response.data.message || '未找到匹配的人员'
        }
      } catch (err) {
        showError('查询失败: ' + (err.response?.data?.error || err.message))
      } finally {
        loading.value = false
      }
    }

    // 根据花名查询拥有者
    const searchByFlower = async () => {
      if (!searchFlowerName.value.trim()) {
        showError('请输入花朵名称')
        return
      }

      clearMessages()
      loading.value = true
      searchResults.value = []
      searchMessage.value = ''

      try {
        const response = await axios.get(`${API_BASE}/search/flower`, {
          params: { name: searchFlowerName.value }
        })
        
        if (response.data.results && response.data.results.length > 0) {
          searchResults.value = response.data.results
          searchMessage.value = `找到 ${response.data.results.length} 个拥有该花朵的人员`
        } else {
          searchMessage.value = response.data.message || '未找到匹配的花朵'
        }
      } catch (err) {
        showError('查询失败: ' + (err.response?.data?.error || err.message))
      } finally {
        loading.value = false
      }
    }

    // 清除查询结果
    const clearSearch = () => {
      searchResults.value = []
      searchMessage.value = ''
      searchPersonName.value = ''
      searchFlowerName.value = ''
    }

    // 组件挂载时获取数据
    onMounted(() => {
      fetchPersons()
    })

    return {
      persons,
      loading,
      error,
      success,
      form,
      isEditing,
      addFlowerToForm,
      removeFlowerFromForm,
      submitForm,
      editPerson,
      cancelEdit,
      deletePerson,
      searchPersonName,
      searchFlowerName,
      searchResults,
      searchMessage,
      searchByPerson,
      searchByFlower,
      clearSearch
    }
  }
}
</script>

