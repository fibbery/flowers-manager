<template>
  <div class="searchable-select" ref="selectContainer">
    <div class="select-input-wrapper">
      <input
        type="text"
        v-model="searchText"
        :placeholder="placeholder"
        @focus="handleFocus"
        @input="handleInput"
        @keydown.down.prevent="navigateOptions('down')"
        @keydown.up.prevent="navigateOptions('up')"
        @keydown.enter.prevent="selectCurrentOption"
        @keydown.esc="closeDropdown"
        ref="inputRef"
        class="searchable-input"
      />
      <span class="select-arrow" :class="{ 'arrow-up': showDropdown }">▼</span>
      
      <!-- 清除按钮 -->
      <button
        v-if="searchText"
        type="button"
        class="clear-btn"
        @click="clearSelection"
      >
        ✕
      </button>
    </div>

    <!-- 下拉选项列表 -->
    <transition name="dropdown">
      <div 
        v-if="showDropdown && filteredOptions.length > 0" 
        class="options-dropdown"
        :style="dropdownStyle"
      >
        <div
          v-for="(option, index) in filteredOptions"
          :key="option.id"
          class="option-item"
          :class="{ 'option-item-active': index === selectedIndex }"
          @click="selectOption(option)"
          @mouseenter="selectedIndex = index"
        >
          🌺 {{ option.name }}
        </div>
      </div>
      <div 
        v-else-if="showDropdown && searchText" 
        class="options-dropdown"
        :style="dropdownStyle"
      >
        <div class="no-options">
          未找到匹配的花朵
        </div>
      </div>
    </transition>
  </div>
</template>

<script>
import { ref, computed, watch, onMounted, onUnmounted } from 'vue'

export default {
  name: 'SearchableSelect',
  props: {
    modelValue: {
      type: String,
      default: ''
    },
    options: {
      type: Array,
      default: () => []
    },
    placeholder: {
      type: String,
      default: '请选择或搜索'
    }
  },
  emits: ['update:modelValue'],
  setup(props, { emit }) {
    const searchText = ref(props.modelValue || '')
    const showDropdown = ref(false)
    const selectedIndex = ref(-1)
    const inputRef = ref(null)
    const selectContainer = ref(null)
    const dropdownStyle = ref({})

    // 过滤选项
    const filteredOptions = computed(() => {
      if (!searchText.value) {
        return props.options
      }
      const keyword = searchText.value.toLowerCase()
      return props.options.filter(option => 
        option.name.toLowerCase().includes(keyword)
      )
    })

    // 计算下拉框位置
    const updateDropdownPosition = () => {
      if (!inputRef.value) return
      
      const rect = inputRef.value.getBoundingClientRect()
      dropdownStyle.value = {
        top: `${rect.bottom + 4}px`,
        left: `${rect.left}px`,
        width: `${rect.width}px`
      }
    }

    // 监听modelValue变化
    watch(() => props.modelValue, (newValue) => {
      searchText.value = newValue || ''
    })

    // 处理焦点
    const handleFocus = () => {
      updateDropdownPosition()
      showDropdown.value = true
      selectedIndex.value = -1
    }

    // 处理输入
    const handleInput = () => {
      updateDropdownPosition()
      showDropdown.value = true
      selectedIndex.value = -1
      emit('update:modelValue', searchText.value)
    }

    // 选择选项
    const selectOption = (option) => {
      searchText.value = option.name
      emit('update:modelValue', option.name)
      showDropdown.value = false
      selectedIndex.value = -1
    }

    // 键盘导航
    const navigateOptions = (direction) => {
      if (filteredOptions.value.length === 0) return

      if (direction === 'down') {
        selectedIndex.value = (selectedIndex.value + 1) % filteredOptions.value.length
      } else if (direction === 'up') {
        selectedIndex.value = 
          selectedIndex.value <= 0 
            ? filteredOptions.value.length - 1 
            : selectedIndex.value - 1
      }
    }

    // 选择当前高亮项
    const selectCurrentOption = () => {
      if (selectedIndex.value >= 0 && filteredOptions.value[selectedIndex.value]) {
        selectOption(filteredOptions.value[selectedIndex.value])
      } else {
        showDropdown.value = false
      }
    }

    // 关闭下拉框
    const closeDropdown = () => {
      showDropdown.value = false
      selectedIndex.value = -1
    }

    // 清除选择
    const clearSelection = () => {
      searchText.value = ''
      emit('update:modelValue', '')
      showDropdown.value = true
      inputRef.value?.focus()
    }

    // 点击外部关闭
    const handleClickOutside = (event) => {
      if (selectContainer.value && !selectContainer.value.contains(event.target)) {
        closeDropdown()
      }
    }

    // 生命周期
    onMounted(() => {
      document.addEventListener('click', handleClickOutside)
      window.addEventListener('scroll', updateDropdownPosition, true)
      window.addEventListener('resize', updateDropdownPosition)
    })

    onUnmounted(() => {
      document.removeEventListener('click', handleClickOutside)
      window.removeEventListener('scroll', updateDropdownPosition, true)
      window.removeEventListener('resize', updateDropdownPosition)
    })

    return {
      searchText,
      showDropdown,
      selectedIndex,
      filteredOptions,
      inputRef,
      selectContainer,
      dropdownStyle,
      handleFocus,
      handleInput,
      selectOption,
      navigateOptions,
      selectCurrentOption,
      closeDropdown,
      clearSelection
    }
  }
}
</script>

<style scoped>
.searchable-select {
  position: relative;
  width: 100%;
}

.select-input-wrapper {
  position: relative;
  width: 100%;
}

.searchable-input {
  width: 100%;
  padding: 12px 60px 12px 16px;
  border: 2px solid #dee2e6;
  border-radius: 8px;
  font-size: 16px;
  transition: all 0.3s ease;
  background: white;
}

.searchable-input:focus {
  outline: none;
  border-color: #667eea;
  box-shadow: 0 0 0 3px rgba(102, 126, 234, 0.1);
}

.select-arrow {
  position: absolute;
  right: 16px;
  top: 50%;
  transform: translateY(-50%);
  color: #667eea;
  font-size: 12px;
  pointer-events: none;
  transition: transform 0.3s ease;
}

.select-arrow.arrow-up {
  transform: translateY(-50%) rotate(180deg);
}

.clear-btn {
  position: absolute;
  right: 40px;
  top: 50%;
  transform: translateY(-50%);
  background: #dc3545;
  border: none;
  color: white;
  width: 20px;
  height: 20px;
  border-radius: 50%;
  cursor: pointer;
  font-size: 12px;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.2s ease;
}

.clear-btn:hover {
  background: #c82333;
  transform: translateY(-50%) scale(1.1);
}

.options-dropdown {
  position: fixed;
  margin-top: 4px;
  background: white;
  border: 2px solid #667eea;
  border-radius: 8px;
  box-shadow: 0 4px 12px rgba(102, 126, 234, 0.2);
  max-height: 250px;
  overflow-y: auto;
  z-index: 10000;
}

.option-item {
  padding: 10px 16px;
  cursor: pointer;
  transition: all 0.2s ease;
  font-size: 15px;
  color: #333;
}

.option-item:hover,
.option-item-active {
  background: linear-gradient(135deg, #f0f3ff 0%, #e8ecff 100%);
  color: #667eea;
  font-weight: 500;
}

.no-options {
  padding: 20px;
  text-align: center;
  color: #6c757d;
  font-style: italic;
}

/* 下拉动画 */
.dropdown-enter-active, .dropdown-leave-active {
  transition: all 0.2s ease;
}

.dropdown-enter-from {
  opacity: 0;
  transform: translateY(-10px);
}

.dropdown-leave-to {
  opacity: 0;
  transform: translateY(-5px);
}

/* 滚动条样式 */
.options-dropdown::-webkit-scrollbar {
  width: 6px;
}

.options-dropdown::-webkit-scrollbar-track {
  background: #f1f1f1;
  border-radius: 4px;
}

.options-dropdown::-webkit-scrollbar-thumb {
  background: #667eea;
  border-radius: 4px;
}

.options-dropdown::-webkit-scrollbar-thumb:hover {
  background: #5568d3;
}
</style>


