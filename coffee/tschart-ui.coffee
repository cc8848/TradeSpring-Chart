@TradeSpring ?= {}
exports = @TradeSpring

class TradeSpring.ChartUI
  @init = (view, d, h) ->
        startScrolling = (callback) ->
          return  unless scrolling
          callback()
          setTimeout (->
            startScrolling callback
          ), (if new Date - scrolling < 1000 then 50 else 10)
        scrolling = false
        $("#right").mousedown(->
          scrolling = new Date
          startScrolling ->
            view.scroll_right()
        ).mouseup ->
          scrolling = false

        $("#left").mousedown(->
          scrolling = new Date
          startScrolling ->
            view.scroll_left()
        ).mouseup ->
          scrolling = false

        $('#info-left').click(->
          $('.infobox').css({right: '', left:'10px'}))

        $('#info-right').click(->
          $('.infobox').css({left: '', right:'10px'}))

        last_x = undefined
        last_center = undefined
        view.chart_view.mousewheel (ev, delta) ->
          center_item = (if last_x and last_x == ev.clientX then last_center else view.cursor_item)
          last_x = ev.clientX
          last_center = center_item
          if delta > 0
            view.zoomin center_item
          else view.zoomout center_item  if delta < 0
          false

        $("#zoomin").click ->
          view.zoomin()

        $("#zoomout").click ->
          view.zoomout()

        $("#end").click ->
          view.init_width()
          view.on_view_change()

        h.prev = d.start_price
        $('.prev', h).text(d.start_price)


  @init_connection_status = (hpipe) ->
        timer_update = undefined
        status = $("#connection-status")
        $(hpipe).bind("connected", ->
          status.addClass("connected").text "Connected"
          clearTimeout timer_update  if timer_update
          $("form.chat-action input").removeAttr "disabled"
        ).bind("disconnected", ->
          status.removeClass("connected").text "Server disconnected. "
          $("form.chat-action input").attr "disabled", "disabled"
        ).bind "reconnecting", (e, data) ->
          retry = new Date(new Date().getTime() + data.after * 1000)
          try_now = $("<span/>").text("Try now").click(data.try_now)
          timer = $("<span/>")
          do_timer_update = ->
            timer.text Math.ceil((retry - new Date()) / 1000) + "s. "
            timer_update = window.setTimeout(do_timer_update, 1000)

          status.text("Server disconnected.  retry in ").append(timer).append try_now
          do_timer_update()

  @set_day_high = (h, day_high, view) ->
        if !h.day_high || day_high > h.day_high
          h.day_high = day_high
          $('.high', h).text(day_high)
          view.price_label_high.text(day_high).css('top', view.candle_zone.val_to_y(day_high))


  @set_day_low = (h, day_low, view) ->
        if !h.day_low  || day_low  < h.day_low
          h.day_low = day_low
          $('.low', h).text(day_low)
          view.price_label_low.text(day_low).css('top', view.candle_zone.val_to_y(day_low))

  @init_live_events = (view, hpipe, h) ->
        $(hpipe).bind("message.tick", (e, d) =>
                view.on_new_event(d)
                if h
                  change = d.prices[CLOSE] - h.prev
                  h.last = d.prices[CLOSE]
                  $('.datetime', h).text(d.datetime)
                  $('.current', h).text(h.last)
                  $('.change', h).text((if change >= 0 then '+' else '') + change.toString())
                  $('.volume', h).text(d.cumvol)
                  if d.prices[CLOSE] > h.prev
                    $('.current', h).addClass('up').removeClass('down')
                    $('.change', h).addClass('up').removeClass('down')
                  else
                    $('.current', h).removeClass('up').addClass('down')
                    $('.change', h).removeClass('up').addClass('down')
                @set_day_high(h, d.prices[HIGH], view)
                @set_day_low(h, d.prices[LOW], view)
        ).bind("message.bar", (e, d) ->
            view.on_new_event(d)
        )
