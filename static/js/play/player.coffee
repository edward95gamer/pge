class @Player
  constructor:()->
    #src = document.getElementById("code").innerText
    @source_count = 0
    @sources = {}
    @resources = resources
    if resources.sources?
      for source in resources.sources
        @loadSource(source)
    else
      @sources.main = document.getElementById("code").innerText
      @start()

  loadSource:(source)->
    req = new XMLHttpRequest()
    req.onreadystatechange = (event) =>
      if req.readyState == XMLHttpRequest.DONE
        if req.status == 200
          name = source.file.split(".")[0]
          @sources[name] = req.responseText
          @source_count++
          if @source_count>=resources.sources.length and not @runtime?
            @start()

    req.open "GET",location.origin+location.pathname+"ms/#{source.file}?v=#{source.version}"
    req.send()

  start:()->
    @runtime = new Runtime((if window.exported_project then "" else location.origin+location.pathname),@sources,resources,@)

    @client = new PlayerClient @

    wrapper = document.getElementById("canvaswrapper")
    wrapper.appendChild @runtime.screen.canvas

    window.addEventListener "resize",()=>@resize()
    @resize()
    #@runtime.start()

    touchStartListener = (event)=>
      event.preventDefault()
      #event.stopPropagation()
      #event.stopImmediatePropagation()
      @runtime.screen.canvas.removeEventListener "touchstart",touchStartListener
      true

    touchListener = (event)=>
      #event.preventDefault()
      #event.stopPropagation()
      #event.stopImmediatePropagation()
      #@runtime.screen.canvas.removeEventListener "touchend",touchListener
      @setFullScreen()
      true

    @runtime.screen.canvas.addEventListener "touchstart",touchStartListener
    @runtime.screen.canvas.addEventListener "touchend",touchListener
    @runtime.start()

    window.addEventListener "message",(msg)=>@messageReceived(msg)

    @postMessage
      name: "focus"

  resize:()->
    @runtime.screen.resize()
    if @runtime.vm?
      if not @runtime.vm.context.global.draw?
        @runtime.update_memory = {}
        for file,src of @runtime.sources
          @runtime.updateSource(file,src,false)

  setFullScreen:()->
    if document.documentElement.webkitRequestFullScreen? and not document.webkitIsFullScreen
      document.documentElement.webkitRequestFullScreen()
    else if document.documentElement.requestFullScreen? and not document.fullScreen
      document.documentElement.requestFullScreen()
    else if document.documentElement.mozRequestFullScreen? and not document.mozFullScreen
      document.documentElement.mozRequestFullScreen()

    if window.screen? and window.screen.orientation? and window.orientation in ["portrait","landscape"]
      window.screen.orientation.lock(window.orientation).then(null, (error)->
        #console.error error
      )

  reportError:(err)->
    @postMessage
      name:"error"
      data: err

  log:(text)->
    @postMessage
      name:"log"
      data: text

  messageReceived:(msg)->
    data = msg.data
    try
      data = JSON.parse data
      switch data.name
        when "command"
          res = @runtime.runCommand data.line
          if not data.line.trim().startsWith("print")
            @postMessage
              name: "output"
              data: res
              id: data.id

        when "pause"
          @runtime.stop()

        when "resume"
          @runtime.resume()

        when "code_updated"
          code = data.code
          file = data.file.split(".")[0]
          if @runtime.vm?
            @runtime.vm.clearWarnings()
          @runtime.updateSource(file,code,true)

        when "sprite_updated"
          file = data.file
          @runtime.updateSprite(file,0,data.data,data.properties)

        when "map_updated"
          file = data.file
          @runtime.updateMap(file,0,data.data)

    catch err
      console.error err

  postMessage:(data)->
    if window != window.parent
      window.parent.postMessage JSON.stringify(data),"*"

window.addEventListener "load",()->
  window.player = new Player()
  document.body.focus()

if navigator.serviceWorker? and not window.skip_service_worker
  navigator.serviceWorker.register('sw.js', { scope: location.pathname }).then((reg)->
    console.log('Registration succeeded. Scope is' + reg.scope)
  ).catch (error)->
    console.log('Registration failed with' + error)
