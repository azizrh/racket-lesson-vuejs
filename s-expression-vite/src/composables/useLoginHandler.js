// composables/useLoginHandler.js
export function useLoginHandler(api, auth, lessons) {
  
  const loginWithUsername = async () => {
    auth.loginError.value = ""
    const uname = (auth.loginUsername.value || "").trim()
    
    if (!uname) {
      auth.loginError.value = "Please enter a username."
      return
    }
    
    try {
      const user = await api.loginWithUsername(uname)
      auth.setUser(user)
      auth.closeLogin()
      await lessons.bootstrapLessons()
    } catch (e) {
      console.error(e)
      auth.loginError.value = e?.message || "Failed to log in."
    }
  }

  return {
    loginWithUsername
  }
}