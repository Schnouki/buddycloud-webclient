{ BaseView } = require 'views/base'
{ PostView } = require 'views/channel/post'
{ EventHandler } = require 'util'

class exports.CommentsView extends BaseView
    template: require 'templates/channel/comments'

    initialize: ({@parent}) ->
        super
        @views = {}
        @model.bind 'change', @render
        @model.forEach @add_comment
        @model.bind 'add', @add_comment

    events:
        'click .createComment': 'createComment'

    createComment: EventHandler ->
        text = @$('textarea')
        unless text.val() is ""
            post =
                content: text.val()
                author:
                    name: app.users.current.get 'jid'
                in_reply_to: @model.parent.id
            node = @model.parent.collection.parent
            app.handler.data.publish node, post, =>
                    post.content = value:post.content
                    #app.handler.data.add_post node, post
                    @el.find('.newTopic').removeClass 'write'
                    text.val ""

    add_comment: (comment) =>
        entry = @views[comment.cid] ?= new PostView
            type:'comment'
            model:comment
            parent:this

        i = @model.indexOf(comment)
        newerComment = @views[@model.at(i - 1)?.cid]
        if newerComment
            newerComment.el.after entry.el
        else
            @el.prepend entry.el
        do entry.render

    render: =>
        @update_attributes()
        super
        for cid, entry of @views
            entry.render()

    update_attributes: ->
        @user = @parent.parent.parent.user # topicpostview.postsview.channelview

