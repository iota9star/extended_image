part of 'extended_gesture.dart';

///
///  create by zmtzawqlp on 2019/6/14
///

/// for loading/failed widget
class ExtendedImageSlidePageHandler extends StatefulWidget {
  final Widget child;
  final ExtendedImageSlidePageState extendedImageSlidePageState;

  ExtendedImageSlidePageHandler(this.child, this.extendedImageSlidePageState);

  @override
  ExtendedImageSlidePageHandlerState createState() =>
      ExtendedImageSlidePageHandlerState();
}

class ExtendedImageSlidePageHandlerState
    extends State<ExtendedImageSlidePageHandler> {
  Offset _startingOffset;

  @override
  Widget build(BuildContext context) {
    Widget result = GestureDetector(
      onScaleStart: _handleScaleStart,
      onScaleUpdate: _handleScaleUpdate,
      onScaleEnd: _handleScaleEnd,
      child: widget.child,
      behavior: HitTestBehavior.translucent,
    );

    if (widget.extendedImageSlidePageState != null &&
        widget.extendedImageSlidePageState.widget.slideType ==
            SlideType.onlyImage) {
      var extendedImageSlidePageState = widget.extendedImageSlidePageState;
      result = Transform.translate(
        offset: extendedImageSlidePageState.offset,
        child: Transform.scale(
          scale: extendedImageSlidePageState.scale,
          child: result,
        ),
      );
    }
    return result;
  }

  void _handleScaleStart(ScaleStartDetails details) {
    widget.extendedImageSlidePageState?._touching = true;
    widget.extendedImageSlidePageState?.slidePageController
        ?._attachExtendedImageSlidePageHandlerState(this);
    _startingOffset = details.focalPoint;
  }

  Offset _updatePageGestureStartingOffset;

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    ///whether gesture page
    if (widget.extendedImageSlidePageState != null && details.scale == 1.0) {
      //var offsetDelta = (details.focalPoint - _startingOffset);

      var delta = (details.focalPoint - _startingOffset).distance;

      if (doubleCompare(delta, minGesturePageDelta) > 0) {
        _updatePageGestureStartingOffset ??= details.focalPoint;
        widget.extendedImageSlidePageState?._slide(
          details.focalPoint - _updatePageGestureStartingOffset,
        );
      }
    }
  }

  void _handleScaleEnd(ScaleEndDetails details) {
    widget.extendedImageSlidePageState?._touching = false;
    if (widget.extendedImageSlidePageState != null &&
        widget.extendedImageSlidePageState.isSliding) {
      _updatePageGestureStartingOffset = null;
      widget.extendedImageSlidePageState?._endSlide();
      return;
    }
  }

  void slide() {
    if (mounted) {
      setState(() {});
    }
  }
}
