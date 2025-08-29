// composables/useAuth.js
import { ref } from 'vue'

export function useAuth() {
  // State
  const username = ref(null)
  const userId = ref(null)
  const user = ref(null)
  const showLogin = ref(false)
  const loginUsername = ref("")
  const loginError = ref("")
  
  // Methods
  const setUser = (userData) => {
    user.value = userData || null
    username.value = userData?.username || null
    userId.value = userData?.user_id || null
    if (username.value) {
      localStorage.setItem("username", username.value)
    }
  }

  const loadLocalUser = () => {
    const raw = localStorage.getItem("username")
    username.value = raw || null
  }

  const logout = (silent = false) => {
    localStorage.removeItem("username")
    user.value = null
    username.value = null
    userId.value = null
    if (!silent) openLogin()
  }

  const openLogin = () => {
    showLogin.value = true
    loginUsername.value = username.value || ""
    loginError.value = ""
  }

  const closeLogin = () => {
    showLogin.value = false
  }

  return {
    // State
    username,
    userId,
    user,
    showLogin,
    loginUsername,
    loginError,
    
    // Methods
    setUser,
    loadLocalUser,
    logout,
    openLogin,
    closeLogin,
  }
}