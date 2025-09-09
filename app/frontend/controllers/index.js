// Import all controller files and register them
export function registerControllers(application) {
  const controllers = import.meta.glob('./**/*_controller.js', { eager: true })
  
  Object.entries(controllers).forEach(([path, controller]) => {
    // Extract controller name from file path
    // e.g., './hello_controller.js' -> 'hello'
    // e.g., './financial_chart_controller.js' -> 'financial-chart'
    const name = path.match(/\.\/(.+)_controller\.js$/)?.[1]?.replace(/_/g, '-')
    
    if (name && controller.default) {
      console.log(`Registering Stimulus controller: ${name}`)
      application.register(name, controller.default)
    }
  })
}