{ RequestHandler } = require 'handlers/request'

class exports.Connector extends Backbone.EventHandler

    constructor: (@handler, @connection) ->
        @handler.bind 'connecting', => @trigger 'connection:start'
        @handler.bind 'connected',  => @trigger 'connection:established'
        @request = new RequestHandler
        app.handler.request = @request.handler
        @connection.buddycloud.addNotificationListener @on_notification

    replayNotifications: =>
        @connection.buddycloud.replayNotifications()

    publish: (nodeid, item, success, error) =>
        @request (done) =>
            @connection.buddycloud.publishAtom nodeid, item
            , (stanza) =>
                app.debug "publish", stanza
                success? stanza
                done()
            , (e) =>
                app.error "publish", nodeid, e
                error? e
                done()

    subscribe: (nodeid, callback) =>
        @request (done) =>
            # TODO: subscribe channel
            @connection.buddycloud.subscribeNode nodeid, (stanza) =>
                app.debug "subscribe", stanza
                userJid = Strophe.getBareJidFromJid(@connection.jid)
                @trigger 'subscription',
                    jid: userJid
                    node: nodeid
                    subscription: 'subscribed' # FIXME
                callback? stanza
                done()
            , =>
                app.error "subscribe", nodeid
                done()

    unsubscribe: (nodeid, callback) =>
        @request (done) =>
            @connection.buddycloud.unsubscribeNode nodeid, (stanza) =>
                app.debug "unsubscribe", stanza
                userJid = Strophe.getBareJidFromJid(@connection.jid)
                @trigger 'subscription',
                    jid: userJid
                    node: nodeid
                    subscription: 'unsubscribed'
                callback? stanza
                done()
            , =>
                app.error "unsubscribe", nodeid
                done()

#     start_fetch_node_posts: (nodeid) =>
#         success = (posts) =>
#             for post in posts
#                 @trigger "post", post, nodeid
#         error = =>
#             app.error "fetch_node_posts", nodeid, arguments
#         @connection.buddycloud.getChannelPostStream nodeid, success, error

    get_node_posts: (nodeid, callback) =>
        @request (done) =>
            success = (posts) =>
                for post in posts
                    if post.content?
                        @trigger "post", post, nodeid
                    else if post.subscriptions?
                        for own nodeid_, subscription of post.subscriptions
                            @trigger 'subscription', subscription
                callback? posts
                done()
            error = (e) =>
                app.error "get_node_posts", nodeid, arguments
                @trigger 'node:error', nodeid, e
                callback? []
                done()
            @connection.buddycloud.getChannelPosts(
                nodeid, success, error, @connection.timeout)

    get_node_metadata: (nodeid, callback) =>
        @request (done) =>
            success = (metadata) =>
                @trigger 'metadata', nodeid, metadata
                callback? metadata
                done()
            error = (e) =>
                app.error "get_node_metadata", nodeid, arguments
                @trigger 'node:error', nodeid, e
                callback?()
                done()
            @connection.buddycloud.getMetadata(
                nodeid, success, error, @connection.timeout)

    # this fetches all subscriptions to a specific node
    get_node_subscriptions: (nodeid, callback) ->
        @request (done) =>
            success = (subscribers) =>
                for own user, subscription of subscribers
                    @trigger 'subscription:node',
                        jid: jid
                        node: nodeid
                        subscription: subscription
                    callback? subscribers
                    done()
            error = (e) =>
                @trigger 'node:error', nodeid, e
                callback?()
                done()
            @connection.buddycloud.getSubscribers(
                nodeid, success, error, @connection.timeout)

    ##
    # notification with type subscription/affiliation already is
    # proper obj
    on_notification: (notification) =>
        switch notification.type
            when 'subscription'
                @trigger 'subscription', notification
            when 'affiliation'
                @trigger 'affiliation', notification
            when 'posts'
                for post in notification.posts
                    @trigger 'post', post, notification.node
            when 'config'
                @trigger 'metadata', notification.node, notification.config
            else
                app.debug "Cannot handle notification for #{notification.type}"
