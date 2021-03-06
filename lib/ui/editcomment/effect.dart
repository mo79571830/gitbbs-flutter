import 'package:fish_redux/fish_redux.dart';
import 'package:gitbbs/model/cachemanager/edit_text_cache_manager.dart';
import 'package:gitbbs/model/event/comments_count_changed_event.dart';
import 'package:gitbbs/model/git_comment.dart';
import 'package:gitbbs/network/GitHttpRequest.dart';
import 'package:gitbbs/ui/editcomment/action.dart';
import 'package:gitbbs/ui/editcomment/state.dart';
import 'package:gitbbs/ui/widget/loading.dart';
import 'package:gitbbs/util/event_bus_helper.dart';
import 'package:markdown_editor/markdown_editor.dart';
import 'package:flutter/material.dart';
import 'package:gitbbs/model/entry/comment_edit_data.dart';

Effect<EditCommentState> buildEffect() {
  return combineEffects(<Object, Effect<EditCommentState>>{
    Lifecycle.initState: _init,
    EditCommentAction.togglePageType: _togglePageType,
    EditCommentAction.checkSubmitComment: _checkSubmitComment,
    EditCommentAction.submitComment: _submitComment
  });
}

void _init(Action action, Context<EditCommentState> ctx) async {
  var text = await EditTextCacheManager.get(ctx.state.getCacheKey());
  if (text?.isNotEmpty == true) {
    ctx.dispatch(EditCommentActionCreator.onUpdateInitTextAction(text));
  }
}

void _togglePageType(Action action, Context<EditCommentState> ctx) async {
  var pageType = ctx.state.getCurrentPage();
  if (pageType == PageType.preview) {
    pageType = PageType.editor;
  } else {
    pageType = PageType.preview;
  }
  ctx.state.mdKey.currentState.setCurrentPage(pageType);
  ctx.dispatch(EditCommentActionCreator.pageTypeChangedAction());
}

void _submitComment(Action action, Context<EditCommentState> ctx) async {
  String body = ctx.state.getBody();
  GitHttpRequest request = GitHttpRequest.getInstance();
  GitComment comment;
  var dialog = LoadingDialog.show(ctx.context);
  if (ctx.state.type == Type.modify) {
    String commentId = ctx.state.comment.getId();
    bool success = await request.modifyComment(commentId, body);
    if (success) {
      comment = ctx.state.comment;
      comment.setBody(body);
    }
  } else {
    String issueId = ctx.state.issue.getId();
    comment = await request.addComment(issueId, body);
    if (comment != null) {
      EventBusHelper.fire(
          CommentCountChangedEvent(true, ctx.state.issue.getNumber()));
    }
  }
  dialog.dismiss();
  if (comment != null) {
    ctx.state.scaffoldKey.currentState
        .showSnackBar(SnackBar(content: Text('????????????')));
    EditTextCacheManager.delete(ctx.state.getCacheKey());
    Navigator.of(ctx.context).pop(comment);
    return;
  }
  ctx.state.scaffoldKey.currentState
      .showSnackBar(SnackBar(content: Text('????????????')));
}

void _checkSubmitComment(Action action, Context<EditCommentState> ctx) {
  if (ctx.state.isBodyEmpty()) {
    ctx.state.scaffoldKey.currentState
        .showSnackBar(SnackBar(content: Text('??????????????????')));
    return;
  }
  showDialog(
      context: ctx.context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text('??????'),
          content: Text('?????????????????????'),
          actions: <Widget>[
            FlatButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('??????')),
            FlatButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  ctx.dispatch(EditCommentActionCreator.submitCommentAction());
                },
                child: Text('??????')),
          ],
        );
      });
}
