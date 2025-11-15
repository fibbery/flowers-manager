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
      <button 
        class="tab-button" 
        :class="{ active: activeTab === 'library' }"
        @click="activeTab = 'library'"
      >
        🌺 花库管理
      </button>
      <button 
        class="tab-button" 
        :class="{ active: activeTab === 'garden' }"
        @click="activeTab = 'garden'"
      >
        🏡 花坊管理
      </button>
    </div>

    <!-- 查询区域 -->
    <div v-show="activeTab === 'search'" class="tab-content search-section">
      <h2>🔍 智能查询</h2>
      <div class="unified-search">
        <div class="search-box-unified">
          <div class="search-input-group-unified">
            <div class="search-input-wrapper">
              <input
                type="text"
                v-model="searchKeyword"
                placeholder="输入人名或花名进行查询（支持模糊匹配，留空显示全部）"
                @keyup.enter="performSearch"
                @input="handleSearchInput"
                @focus="showSuggestions = true"
                @keydown.down.prevent="navigateSuggestions('down')"
                @keydown.up.prevent="navigateSuggestions('up')"
                ref="searchInput"
              />
              
              <!-- 下拉建议列表 -->
              <transition name="dropdown-fade">
                <div 
                  v-if="showSuggestions && (filteredSuggestions.persons.length > 0 || filteredSuggestions.flowers.length > 0)" 
                  class="suggestions-dropdown"
                  @mousedown.prevent
                >
                  <!-- 人名建议 -->
                  <div v-if="filteredSuggestions.persons.length > 0" class="suggestions-group">
                    <div class="suggestions-group-title">👤 人名</div>
                    <div
                      v-for="(person, index) in filteredSuggestions.persons"
                      :key="'person-' + person.id"
                      class="suggestion-item"
                      :class="{ 'suggestion-item-active': selectedSuggestionIndex === index }"
                      @click="selectSuggestion(person.name)"
                      @mouseenter="selectedSuggestionIndex = index"
                    >
                      <span class="suggestion-icon">👤</span>
                      <span class="suggestion-text">{{ person.name }}</span>
                      <span class="suggestion-count">{{ person.flowers.length }} 朵花</span>
                    </div>
                  </div>
                  
                  <!-- 花名建议 -->
                  <div v-if="filteredSuggestions.flowers.length > 0" class="suggestions-group">
                    <div class="suggestions-group-title">🌺 花名</div>
                    <div
                      v-for="(flower, index) in filteredSuggestions.flowers"
                      :key="'flower-' + flower.name"
                      class="suggestion-item"
                      :class="{ 'suggestion-item-active': selectedSuggestionIndex === filteredSuggestions.persons.length + index }"
                      @click="selectSuggestion(flower.name)"
                      @mouseenter="selectedSuggestionIndex = filteredSuggestions.persons.length + index"
                    >
                      <span class="suggestion-icon">🌺</span>
                      <span class="suggestion-text">{{ flower.name }}</span>
                      <span class="suggestion-count">
                        {{ flower.firstOwner }}{{ flower.count > 1 ? `等 ${flower.count} 人` : '' }}拥有
                      </span>
                    </div>
                  </div>
                </div>
              </transition>
            </div>
            <button class="btn btn-primary" @click="performSearch">
              🔍 搜索
            </button>
          </div>
          <p class="search-hint">💡 输入时显示建议列表，点击即可快速搜索</p>
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

    <!-- 花库管理 -->
    <div v-show="activeTab === 'library'" class="tab-content flower-library-section">
      <h2>🌺 花库管理</h2>
      
      <!-- 添加新花到花库 -->
      <div class="library-add-form">
        <div class="library-input-group">
          <input
            type="text"
            v-model="newLibraryFlower"
            placeholder="输入新花朵名称（如：玫瑰、栀子花）"
            @keyup.enter="addToLibrary"
          />
          <button class="btn btn-primary" @click="addToLibrary">
            ➕ 添加到花库
          </button>
        </div>
      </div>

      <!-- 花库列表 -->
      <div v-if="flowerLibrary.length > 0" class="library-list">
        <div class="library-header">
          <h3>花库列表 <span class="result-count">（共 {{ flowerLibrary.length }} 种）</span></h3>
        </div>
        <div class="library-grid">
          <div v-for="flower in flowerLibrary" :key="flower.id" class="library-card">
            <span class="library-flower-name">🌺 {{ flower.name }}</span>
            <div class="library-actions">
              <button
                class="btn btn-danger btn-small"
                @click="deleteFromLibrary(flower.id, flower.name)"
                title="删除"
              >
                删除
              </button>
            </div>
          </div>
        </div>
      </div>
      
      <!-- 空状态 -->
      <div v-else class="empty-state">
        <div class="empty-state-icon">🌼</div>
        <p>花库还是空的，添加一些常用的花朵吧！</p>
      </div>
    </div>

    <!-- 花坊管理 -->
    <div v-show="activeTab === 'garden'" class="tab-content flower-garden-section">
      <h2>🏡 花坊管理</h2>
      
      <!-- 花坊名单录入 -->
      <div class="garden-input-section">
        <div class="garden-input-header">
          <h3>📝 花坊名单</h3>
          <button 
            v-if="!isEditingGardenList && gardenFlowerList"
            class="btn btn-warning btn-small" 
            @click="startEditGardenList"
          >
            ✏️ 编辑名单
          </button>
        </div>
        <p class="garden-hint">请输入花朵名称，用逗号分隔（如：玫瑰,百合,栀子花）</p>
        <textarea
          v-model="gardenFlowerList"
          :disabled="!isEditingGardenList"
          placeholder="玫瑰,百合,栀子花,太阳花,菊花,康乃馨,郁金香,牡丹,茉莉花,桂花"
          class="garden-textarea"
          :class="{ 'textarea-disabled': !isEditingGardenList }"
          rows="4"
        ></textarea>
        <div v-if="isEditingGardenList" class="garden-edit-actions">
          <button class="btn btn-primary btn-large" @click="updateGardenList">
            💾 保存花坊名单
          </button>
          <button 
            v-if="gardenFlowerList" 
            class="btn btn-secondary btn-large" 
            @click="cancelEditGardenList"
          >
            取消
          </button>
        </div>
      </div>

      <!-- 待分配的花朵（对比结果） -->
      <div v-if="unownedGardenFlowers.length > 0" class="unowned-section">
        <div class="unowned-header">
          <h3>
            ❌ 待分配的花朵 
            <span class="result-count-warning">（共 {{ unownedGardenFlowers.length }} 种）</span>
          </h3>
          <p class="unowned-desc">💡 这些花在花坊中有，但还没有任何人拥有</p>
        </div>
        <div class="unowned-grid">
          <div v-for="(flower, index) in unownedGardenFlowers" :key="index" class="unowned-card">
            <span class="unowned-flower-name">🌺 {{ flower }}</span>
            <span class="unowned-badge">待分配</span>
          </div>
        </div>
      </div>

      <!-- 已分配的花朵 -->
      <div v-if="ownedGardenFlowers.length > 0" class="owned-section">
        <div class="owned-header">
          <h3>
            ✅ 已分配的花朵 
            <span class="result-count-success">（共 {{ ownedGardenFlowers.length }} 种）</span>
          </h3>
          <p class="owned-desc">💡 这些花至少有一个人拥有</p>
        </div>
        <div class="owned-grid">
          <div v-for="(flower, index) in ownedGardenFlowers" :key="index" class="owned-card">
            <span class="owned-flower-name">🌺 {{ flower }}</span>
            <button 
              class="owned-badge-btn" 
              @click="showFlowerOwners(flower)"
              :title="'点击查看拥有者'"
            >
              ✓ {{ getFlowerOwnersCount(flower) }}人
            </button>
          </div>
        </div>
      </div>

      <!-- 统计信息 -->
      <div v-if="gardenFlowerArray.length > 0" class="garden-summary">
        <h3>📊 统计信息</h3>
        <div class="summary-stats">
          <div class="summary-item">
            <div class="summary-label">花坊总数</div>
            <div class="summary-value total">{{ gardenFlowerArray.length }}</div>
          </div>
          <div class="summary-item">
            <div class="summary-label">已分配</div>
            <div class="summary-value owned">{{ ownedGardenFlowers.length }}</div>
          </div>
          <div class="summary-item">
            <div class="summary-label">待分配</div>
            <div class="summary-value unowned">{{ unownedGardenFlowers.length }}</div>
          </div>
          <div class="summary-item">
            <div class="summary-label">分配率</div>
            <div class="summary-value rate">{{ gardenCompletionRate }}%</div>
          </div>
        </div>
      </div>

      <!-- 空状态 -->
      <div v-if="gardenFlowerArray.length === 0" class="empty-state">
        <div class="empty-state-icon">🏡</div>
        <p>还没有录入花坊名单，在上方输入框录入吧！</p>
        <p class="help-text-secondary">格式示例：玫瑰,百合,栀子花,太阳花</p>
      </div>
    </div>

    <!-- 花朵拥有者弹窗 -->
    <div v-if="showOwnersModal" class="modal-overlay" @click="closeOwnersModal">
      <div class="modal-content modal-content-small" @click.stop>
        <div class="modal-header">
          <h3>🌺 {{ currentFlowerName }} 的拥有者</h3>
          <button class="close-btn" @click="closeOwnersModal">✕</button>
        </div>
        <div class="modal-body">
          <div class="owners-list">
            <div 
              v-for="(owner, index) in currentFlowerOwnersList" 
              :key="index" 
              class="owner-item"
            >
              <span class="owner-name">👤 {{ owner }}</span>
            </div>
          </div>
        </div>
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
            <SearchableSelect
              v-model="flower.name"
              :options="flowerLibrary"
              placeholder="请选择或搜索花朵"
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
          <p class="help-text">💡 支持搜索过滤，也可以先去"花库管理"添加新花朵</p>
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
              <SearchableSelect
                v-model="newFlowerName"
                :options="flowerLibrary"
                placeholder="请选择或搜索花朵"
              />
              <button class="btn btn-primary" @click="quickAddFlower">
                添加
              </button>
            </div>
            <p class="help-text">💡 支持搜索过滤，系统会自动检查重复</p>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { ref, computed, onMounted, onUnmounted, nextTick } from 'vue'
import axios from 'axios'
import SearchableSelect from './components/SearchableSelect.vue'

export default {
  name: 'App',
  components: {
    SearchableSelect
  },
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
    
    // 花库相关状态
    const flowerLibrary = ref([])
    const newLibraryFlower = ref('')
    
    // 花坊相关状态
    const gardenFlowerList = ref('')
    const isEditingGardenList = ref(true)
    const originalGardenList = ref('')
    
    // 花朵拥有者弹窗状态
    const showOwnersModal = ref(false)
    const currentFlowerName = ref('')
    const currentFlowerOwnersList = ref([])
    

    // Tab 相关状态
    const activeTab = ref('search')

    // 查询相关状态
    const searchKeyword = ref('')
    const searchResults = ref([])
    const searchMessage = ref('')
    const showSuggestions = ref(false)
    const selectedSuggestionIndex = ref(-1)
    const searchInput = ref(null)
    
    // 显示结果：如果有搜索结果显示搜索结果，否则显示所有人员
    const displayResults = computed(() => {
      return searchResults.value.length > 0 ? searchResults.value : persons.value
    })
    
    // 过滤建议列表
    const filteredSuggestions = computed(() => {
      const keyword = searchKeyword.value.trim().toLowerCase()
      
      if (!keyword || keyword.length === 0) {
        return { persons: [], flowers: [] }
      }
      
      // 过滤人名
      const matchedPersons = persons.value
        .filter(p => p.name.toLowerCase().includes(keyword))
        .slice(0, 5) // 最多显示5个
      
      // 收集所有花朵并统计，同时记录拥有者
      const flowersMap = new Map()
      persons.value.forEach(person => {
        person.flowers.forEach(flower => {
          const flowerName = flower.name.toLowerCase()
          if (flowerName.includes(keyword)) {
            if (flowersMap.has(flower.name)) {
              const data = flowersMap.get(flower.name)
              data.count += 1
              data.owners.push(person.name)
            } else {
              flowersMap.set(flower.name, {
                count: 1,
                owners: [person.name]
              })
            }
          }
        })
      })
      
      // 转换为数组并排序
      const matchedFlowers = Array.from(flowersMap.entries())
        .map(([name, data]) => ({ 
          name, 
          count: data.count,
          firstOwner: data.owners[0] // 第一个拥有者
        }))
        .sort((a, b) => b.count - a.count) // 按拥有人数排序
        .slice(0, 5) // 最多显示5个
      
      return {
        persons: matchedPersons,
        flowers: matchedFlowers
      }
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

    // 获取花库
    const fetchFlowerLibrary = async () => {
      try {
        const response = await axios.get(`${API_BASE}/flower-library`)
        flowerLibrary.value = response.data
      } catch (err) {
        showError('获取花库失败: ' + (err.response?.data?.error || err.message))
      }
    }

    // 添加花到花库
    const addToLibrary = async () => {
      const flowerName = newLibraryFlower.value.trim()
      
      if (!flowerName) {
        showError('请输入花朵名称')
        return
      }

      try {
        await axios.post(`${API_BASE}/flower-library`, { name: flowerName })
        showSuccess(`成功添加 "${flowerName}" 到花库！`)
        newLibraryFlower.value = ''
        await fetchFlowerLibrary()
      } catch (err) {
        showError(err.response?.data?.error || err.message)
      }
    }

    // 从花库删除花
    const deleteFromLibrary = async (id, name) => {
      if (!confirm(`确定要从花库中删除 "${name}" 吗？\n\n注意：这不会影响已分配给人员的花朵。`)) {
        return
      }

      try {
        await axios.delete(`${API_BASE}/flower-library/${id}`)
        showSuccess('删除成功！')
        await fetchFlowerLibrary()
      } catch (err) {
        showError(err.response?.data?.error || err.message)
      }
    }

    // 获取花坊名单
    const fetchGarden = async () => {
      try {
        const response = await axios.get(`${API_BASE}/garden`)
        gardenFlowerList.value = response.data.flower_list || ''
        originalGardenList.value = response.data.flower_list || ''
        // 如果有名单则锁定编辑
        isEditingGardenList.value = !response.data.flower_list
      } catch (err) {
        showError('获取花坊名单失败: ' + (err.response?.data?.error || err.message))
      }
    }

    // 开始编辑花坊名单
    const startEditGardenList = () => {
      isEditingGardenList.value = true
    }

    // 取消编辑花坊名单
    const cancelEditGardenList = () => {
      gardenFlowerList.value = originalGardenList.value
      isEditingGardenList.value = false
    }

    // 更新花坊名单
    const updateGardenList = async () => {
      try {
        await axios.post(`${API_BASE}/garden`, {
          flower_list: gardenFlowerList.value
        })
        showSuccess('花坊名单保存成功！')
        originalGardenList.value = gardenFlowerList.value
        isEditingGardenList.value = false
      } catch (err) {
        showError(err.response?.data?.error || err.message)
      }
    }

    // 显示花朵拥有者列表
    const showFlowerOwners = (flowerName) => {
      currentFlowerName.value = flowerName
      currentFlowerOwnersList.value = persons.value
        .filter(person => person.flowers && person.flowers.some(f => f.name === flowerName))
        .map(p => p.name)
      showOwnersModal.value = true
    }

    // 关闭拥有者弹窗
    const closeOwnersModal = () => {
      showOwnersModal.value = false
      currentFlowerName.value = ''
      currentFlowerOwnersList.value = []
    }

    // 解析花坊名单为数组
    const gardenFlowerArray = computed(() => {
      if (!gardenFlowerList.value) return []
      return gardenFlowerList.value
        .split(/[,，]/)
        .map(name => name.trim())
        .filter(name => name.length > 0)
    })

    // 收集所有人拥有的花朵（去重）
    const allOwnedFlowerNames = computed(() => {
      const ownedSet = new Set()
      persons.value.forEach(person => {
        if (person.flowers) {
          person.flowers.forEach(flower => {
            ownedSet.add(flower.name)
          })
        }
      })
      return ownedSet
    })

    // 计算未被拥有的花坊花朵
    const unownedGardenFlowers = computed(() => {
      return gardenFlowerArray.value.filter(flower => 
        !allOwnedFlowerNames.value.has(flower)
      )
    })

    // 计算已被拥有的花坊花朵
    const ownedGardenFlowers = computed(() => {
      return gardenFlowerArray.value.filter(flower => 
        allOwnedFlowerNames.value.has(flower)
      )
    })

    // 获取拥有某朵花的人员列表
    const getFlowerOwners = (flowerName) => {
      const owners = persons.value
        .filter(person => person.flowers && person.flowers.some(f => f.name === flowerName))
        .map(p => p.name)
      return owners.join('、')
    }

    // 获取拥有某朵花的人数
    const getFlowerOwnersCount = (flowerName) => {
      return persons.value.filter(person => 
        person.flowers && person.flowers.some(f => f.name === flowerName)
      ).length
    }

    // 计算花坊完成率
    const gardenCompletionRate = computed(() => {
      if (gardenFlowerArray.value.length === 0) return 0
      const rate = (ownedGardenFlowers.value.length / gardenFlowerArray.value.length) * 100
      return Math.round(rate)
    })

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
      showSuggestions.value = false
      selectedSuggestionIndex.value = -1
    }
    
    // 处理搜索输入
    const handleSearchInput = () => {
      showSuggestions.value = true
      selectedSuggestionIndex.value = -1
    }
    
    // 选择建议项
    const selectSuggestion = (text) => {
      searchKeyword.value = text
      showSuggestions.value = false
      selectedSuggestionIndex.value = -1
      performSearch()
    }
    
    // 键盘导航建议列表
    const navigateSuggestions = (direction) => {
      const totalSuggestions = 
        filteredSuggestions.value.persons.length + 
        filteredSuggestions.value.flowers.length
      
      if (totalSuggestions === 0) return
      
      if (direction === 'down') {
        selectedSuggestionIndex.value = 
          (selectedSuggestionIndex.value + 1) % totalSuggestions
      } else if (direction === 'up') {
        selectedSuggestionIndex.value = 
          selectedSuggestionIndex.value <= 0 
            ? totalSuggestions - 1 
            : selectedSuggestionIndex.value - 1
      }
    }
    
    // 点击外部关闭建议框
    const handleClickOutside = (event) => {
      if (searchInput.value && !searchInput.value.contains(event.target)) {
        showSuggestions.value = false
      }
    }

    // 组件挂载时获取数据
    onMounted(() => {
      fetchPersons()
      fetchFlowerLibrary()
      fetchGarden()
      // 添加点击外部关闭建议框的监听
      document.addEventListener('click', handleClickOutside)
    })
    
    // 组件卸载时移除监听
    onUnmounted(() => {
      document.removeEventListener('click', handleClickOutside)
    })

    return {
      persons,
      loading,
      toast,
      form,
      isEditing,
      activeTab,
      flowerLibrary,
      newLibraryFlower,
      gardenFlowerList,
      gardenFlowerArray,
      unownedGardenFlowers,
      ownedGardenFlowers,
      gardenCompletionRate,
      isEditingGardenList,
      showOwnersModal,
      currentFlowerName,
      currentFlowerOwnersList,
      addFlowerToForm,
      removeFlowerFromForm,
      submitForm,
      editPerson,
      cancelEdit,
      deletePerson,
      addToLibrary,
      deleteFromLibrary,
      updateGardenList,
      startEditGardenList,
      cancelEditGardenList,
      showFlowerOwners,
      closeOwnersModal,
      getFlowerOwners,
      getFlowerOwnersCount,
      searchKeyword,
      searchResults,
      searchMessage,
      displayResults,
      showSuggestions,
      selectedSuggestionIndex,
      filteredSuggestions,
      searchInput,
      performSearch,
      clearSearch,
      switchToSearch,
      handleSearchInput,
      selectSuggestion,
      navigateSuggestions,
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

