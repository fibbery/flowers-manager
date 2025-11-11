<template>
  <div class="container">
    <h1>🌸 花朵管理系统</h1>

    <!-- Toast 提示 -->
    <transition name="toast-fade">
      <div v-if="toast.show" class="toast" :class="toast.type">
        <span class="toast-icon">{{ toast.icon }}</span>
        <span class="toast-message">{{ toast.message }}</span>
      </div>
    </transition>

    <!-- Tab 导航 -->
    <div class="tabs">
      <button 
        class="tab-button" 
        :class="{ active: activeTab === 'search' }"
        @click="switchToSearch"
      >
        🔍 查询
      </button>
      <button 
        class="tab-button" 
        :class="{ active: activeTab === 'add' }"
        @click="activeTab = 'add'"
      >
        ➕ {{ isEditing ? '编辑人员' : '添加人员' }}
      </button>
    </div>

    <!-- 查询区域 -->
    <div v-show="activeTab === 'search'" class="tab-content search-section">
      <h2>🔍 智能查询</h2>
      <div class="unified-search">
        <div class="search-box-unified">
          <div class="search-input-group-unified">
            <input
              type="text"
              v-model="searchKeyword"
              placeholder="输入人名或花名进行查询（支持模糊匹配，留空显示全部）"
              @keyup.enter="performSearch"
            />
            <button class="btn btn-primary" @click="performSearch">
              🔍 搜索
            </button>
          </div>
          <p class="search-hint">💡 自动同时搜索人名和花名，显示所有匹配结果</p>
        </div>
      </div>

      <!-- 加载状态 -->
      <div v-if="loading" class="loading">
        加载中...
      </div>

      <!-- 查询结果 -->
      <div v-else-if="displayResults.length > 0" class="search-results">
        <div class="search-results-header">
          <h3>
            {{ searchMessage || '所有人员' }} 
            <span class="result-count">（共 {{ displayResults.length }} 条）</span>
          </h3>
          <button 
            v-if="searchKeyword" 
            class="btn btn-secondary btn-small" 
            @click="clearSearch"
          >
            清除搜索
          </button>
        </div>
        <div class="persons-grid">
          <div v-for="person in displayResults" :key="person.id" class="person-card">
            <div class="person-header">
              <h3 class="person-name">{{ person.name }}</h3>
              <div class="person-actions">
                <button
                  class="btn btn-success btn-small"
                  @click="showQuickAddFlower(person)"
                  title="快速添加花朵"
                >
                  ➕ 花
                </button>
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
                  :class="{ 'flower-tag-highlight': flower.matched }"
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
      
      <!-- 空状态 -->
      <div v-else class="empty-state">
        <div class="empty-state-icon">🌼</div>
        <p>{{ searchMessage || '还没有添加任何人员，点击"添加人员"标签开始添加吧！' }}</p>
      </div>
    </div>

    <!-- 添加/编辑表单 -->
    <div v-show="activeTab === 'add'" class="tab-content add-form">
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


    <!-- 快速添加花朵弹窗 -->
    <div v-if="showQuickAddModal" class="modal-overlay" @click="closeQuickAddModal">
      <div class="modal-content" @click.stop>
        <div class="modal-header">
          <h3>给 {{ quickAddPerson.name }} 添加花朵</h3>
          <button class="close-btn" @click="closeQuickAddModal">✕</button>
        </div>
        <div class="modal-body">
          <div class="current-flowers" v-if="quickAddPerson.flowers && quickAddPerson.flowers.length > 0">
            <h4>当前拥有的花朵：</h4>
            <div class="flowers-list">
              <span v-for="flower in quickAddPerson.flowers" :key="flower.id" class="flower-tag">
                🌺 {{ flower.name }}
              </span>
            </div>
          </div>
          <div class="quick-add-form">
            <label>添加新花朵</label>
            <div class="quick-add-input-group">
              <input
                type="text"
                v-model="newFlowerName"
                placeholder="输入花朵名称"
                @keyup.enter="quickAddFlower"
                ref="quickAddInput"
              />
              <button class="btn btn-primary" @click="quickAddFlower">
                添加
              </button>
            </div>
            <p class="help-text">💡 提示：系统会自动检查重复</p>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { ref, computed, onMounted, nextTick } from 'vue'
import axios from 'axios'

export default {
  name: 'App',
  setup() {
    const persons = ref([])
    const loading = ref(false)
    const isEditing = ref(false)
    const editingId = ref(null)
    
    // Toast 提示状态
    const toast = ref({
      show: false,
      message: '',
      type: 'success', // success, error, info
      icon: '✓'
    })
    
    const form = ref({
      name: '',
      flowers: []
    })

    // Tab 相关状态
    const activeTab = ref('search')

    // 查询相关状态
    const searchKeyword = ref('')
    const searchResults = ref([])
    const searchMessage = ref('')
    
    // 显示结果：如果有搜索结果显示搜索结果，否则显示所有人员
    const displayResults = computed(() => {
      return searchResults.value.length > 0 ? searchResults.value : persons.value
    })

    // 快速添加花朵相关状态
    const showQuickAddModal = ref(false)
    const quickAddPerson = ref({})
    const newFlowerName = ref('')
    const quickAddInput = ref(null)

    // API 基础 URL - 生产环境使用相对路径
    const API_BASE = process.env.NODE_ENV === 'production' ? '/api' : 'http://localhost:3000/api'

    // Toast 提示函数
    const showToast = (message, type = 'success') => {
      const icons = {
        success: '✓',
        error: '✕',
        info: 'ℹ'
      }
      
      toast.value = {
        show: true,
        message,
        type,
        icon: icons[type]
      }
      
      setTimeout(() => {
        toast.value.show = false
      }, type === 'error' ? 4000 : 2500)
    }

    // 显示错误信息
    const showError = (message) => {
      showToast(message, 'error')
    }

    // 显示成功信息
    const showSuccess = (message) => {
      showToast(message, 'success')
    }

    // 显示提示信息
    const showInfo = (message) => {
      showToast(message, 'info')
    }

    // 获取所有人员
    const fetchPersons = async () => {
      loading.value = true
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
      
      // 切换到添加Tab
      activeTab.value = 'add'
      
      // 滚动到顶部
      window.scrollTo({ top: 0, behavior: 'smooth' })
    }

    // 取消编辑
    const cancelEdit = () => {
      resetForm()
      activeTab.value = 'search'
    }

    // 显示快速添加花朵弹窗
    const showQuickAddFlower = async (person) => {
      quickAddPerson.value = person
      newFlowerName.value = ''
      showQuickAddModal.value = true
      
      // 等待DOM更新后聚焦输入框
      await nextTick()
      if (quickAddInput.value) {
        quickAddInput.value.focus()
      }
    }

    // 关闭快速添加弹窗
    const closeQuickAddModal = () => {
      showQuickAddModal.value = false
      quickAddPerson.value = {}
      newFlowerName.value = ''
    }

    // 快速添加花朵
    const quickAddFlower = async () => {
      const flowerName = newFlowerName.value.trim()
      
      if (!flowerName) {
        showError('请输入花朵名称')
        return
      }

      // 检查是否重复
      const existingFlowers = quickAddPerson.value.flowers || []
      const isDuplicate = existingFlowers.some(f => f.name === flowerName)
      
      if (isDuplicate) {
        showError(`"${flowerName}" 已经存在于 ${quickAddPerson.value.name} 的花朵列表中`)
        return
      }

      try {
        // 合并现有花朵和新花朵
        const allFlowers = [
          ...existingFlowers.map(f => ({ name: f.name })),
          { name: flowerName }
        ]

        // 更新人员信息
        await axios.put(`${API_BASE}/persons/${quickAddPerson.value.id}`, {
          name: quickAddPerson.value.name,
          flowers: allFlowers
        })

        showSuccess(`成功为 ${quickAddPerson.value.name} 添加花朵 "${flowerName}"！`)
        newFlowerName.value = ''
        
        // 刷新列表
        await fetchPersons()
        
        // 更新弹窗中显示的人员信息
        const updatedPerson = persons.value.find(p => p.id === quickAddPerson.value.id)
        if (updatedPerson) {
          quickAddPerson.value = updatedPerson
        }
        
        // 聚焦输入框以便继续添加
        if (quickAddInput.value) {
          quickAddInput.value.focus()
        }
      } catch (err) {
        showError(err.response?.data?.error || err.message)
      }
    }

    // 删除人员
    const deletePerson = async (id, name) => {
      if (!confirm(`确定要删除 "${name}" 及其所有花朵吗？`)) {
        return
      }

      try {
        await axios.delete(`${API_BASE}/persons/${id}`)
        showSuccess('删除成功！')
        await fetchPersons()
      } catch (err) {
        showError(err.response?.data?.error || err.message)
      }
    }

    // 统一智能搜索
    const performSearch = async () => {
      const keyword = searchKeyword.value.trim()
      
      // 如果关键词为空，清除搜索结果，显示所有人员
      if (!keyword) {
        searchResults.value = []
        searchMessage.value = ''
        return
      }

      loading.value = true
      searchResults.value = []
      searchMessage.value = ''

      try {
        // 同时查询人名和花名
        const [personResponse, flowerResponse] = await Promise.all([
          axios.get(`${API_BASE}/search/person`, { params: { name: keyword } }),
          axios.get(`${API_BASE}/search/flower`, { params: { name: keyword } })
        ])
        
        // 合并结果并标记匹配的花朵
        const resultsMap = new Map()
        const matchedFlowersByPerson = new Map() // 记录每个人匹配的花朵ID
        
        // 处理人名搜索结果
        if (personResponse.data.results && personResponse.data.results.length > 0) {
          personResponse.data.results.forEach(person => {
            // 获取完整的人员信息（包含所有花朵）
            const fullPerson = persons.value.find(p => p.id === person.id)
            if (fullPerson) {
              resultsMap.set(person.id, { ...fullPerson })
            }
          })
        }
        
        // 处理花名搜索结果
        if (flowerResponse.data.results && flowerResponse.data.results.length > 0) {
          flowerResponse.data.results.forEach(person => {
            // 获取完整的人员信息
            const fullPerson = persons.value.find(p => p.id === person.id)
            if (fullPerson) {
              // 记录哪些花朵是匹配的
              const matchedFlowers = person.flowers.map(f => f.id)
              matchedFlowersByPerson.set(person.id, matchedFlowers)
              
              if (!resultsMap.has(person.id)) {
                resultsMap.set(person.id, { ...fullPerson })
              }
            }
          })
        }
        
        // 转换为数组并标记匹配的花朵
        const mergedResults = Array.from(resultsMap.values()).map(person => {
          const matchedFlowers = matchedFlowersByPerson.get(person.id) || []
          return {
            ...person,
            flowers: person.flowers.map(flower => ({
              ...flower,
              matched: matchedFlowers.includes(flower.id)
            }))
          }
        })
        
        if (mergedResults.length > 0) {
          searchResults.value = mergedResults
          const personCount = personResponse.data.results?.length || 0
          const flowerCount = flowerResponse.data.results?.length || 0
          
          let message = `找到 ${mergedResults.length} 个匹配结果`
          if (personCount > 0 && flowerCount > 0) {
            message += ` (人名: ${personCount}，花名: ${flowerCount})`
          } else if (personCount > 0) {
            message += ` (匹配人名)`
          } else if (flowerCount > 0) {
            message += ` (匹配花名)`
          }
          
          searchMessage.value = message
        } else {
          searchResults.value = []
          searchMessage.value = '未找到匹配的人员或花朵'
        }
      } catch (err) {
        showError('查询失败: ' + (err.response?.data?.error || err.message))
      } finally {
        loading.value = false
      }
    }
    
    // 切换到查询Tab
    const switchToSearch = () => {
      activeTab.value = 'search'
      // 如果没有搜索结果，确保显示所有人员
      if (searchResults.value.length === 0 && !searchKeyword.value) {
        searchMessage.value = ''
      }
    }

    // 清除查询结果
    const clearSearch = () => {
      searchResults.value = []
      searchMessage.value = ''
      searchKeyword.value = ''
    }

    // 组件挂载时获取数据
    onMounted(() => {
      fetchPersons()
    })

    return {
      persons,
      loading,
      toast,
      form,
      isEditing,
      activeTab,
      addFlowerToForm,
      removeFlowerFromForm,
      submitForm,
      editPerson,
      cancelEdit,
      deletePerson,
      searchKeyword,
      searchResults,
      searchMessage,
      displayResults,
      performSearch,
      clearSearch,
      switchToSearch,
      showQuickAddModal,
      quickAddPerson,
      newFlowerName,
      quickAddInput,
      showQuickAddFlower,
      closeQuickAddModal,
      quickAddFlower
    }
  }
}
</script>

