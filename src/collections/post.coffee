{ Collection } = require './base'
{ Post } = require '../models/post'

class exports.Posts extends Collection
    model: Post

    constructor: ({@parent}) ->
        super()

    initialize: ->
        @parent.bind 'post', (post) =>
            @get_or_create post
        @bind 'add', (post) =>
            # Hook 'change' as Backbone Collections only sort on 'add'
            post.bind 'change', =>
                @sort(silent: true)

    comparator: (post) ->
        - new Date(post.get_last_update()).getTime()


class exports.Comments extends exports.Posts
    comparator: ->
        -1 * super # comments have a reversed posts order

