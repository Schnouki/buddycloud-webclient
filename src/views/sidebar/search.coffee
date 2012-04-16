{ BaseView } = require '../base'
{ EventHandler } = require '../../util'

class exports.Searchbar extends BaseView
    template: require '../../templates/sidebar/search'

    events:
        'search input[type="search"]': 'on_search'

    render: (callback) ->
        super ->
            @$('input[type="search"]').input @on_input

            unless Modernizr.hasEvent 'search' # firefox
                setTimeout => # wtf
                    @$('input').keydown (ev) =>
                        code = ev.keyCode or ev.which
                        return unless code is 13
                        @on_search(ev)
                , 66

            callback?.call(this)

    on_input: (ev) =>
        search = @$('input[type="search"]').val()?.toLowerCase() or ""
        @filter = search
        @trigger 'filter', search

    on_search: EventHandler ->
        input = @$('input[type="search"]')
        search = input.val()?.toLowerCase() or ""

        is_jid = /[^\/]+@[^\/]/.test(search)
        channels = @model.filter(@filter)

        if is_jid or channels.length is 1
            unless is_jid
                search = channels[0].get 'id'
            app.router.navigate search, yes

        input.val ""
        @filter = ""
        @trigger 'filter', ""



