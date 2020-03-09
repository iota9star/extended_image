part of 'extended_gesture.dart';

enum SlideAxis {
  both,
  horizontal,
  vertical,
}

enum SlideType {
  wholePage,
  onlyImage,
}

const _defaultSlideBackDuration = const Duration(milliseconds: 360);

class ExtendedImageSlidePage extends StatefulWidget {
  ///The [child] contained by the ExtendedImageGesturePage.
  final Widget child;

  ///axis of slide
  ///both,horizontal,vertical
  final SlideAxis slideAxis;

  /// slide whole page or only image
  final SlideType slideType;

  final SlidePageController slidePageController;

  ExtendedImageSlidePage({
    this.child,
    SlidePageController slidePageController,
    this.slideAxis: SlideAxis.both,
    this.slideType: SlideType.onlyImage,
    Key key,
  })  : this.slidePageController =
            slidePageController ?? SlidePageController._default(),
        super(key: key);

  @override
  ExtendedImageSlidePageState createState() => ExtendedImageSlidePageState();
}

class ExtendedImageSlidePageState extends State<ExtendedImageSlidePage>
    with SingleTickerProviderStateMixin {
  bool _isSliding = false;

  ///whether is sliding page
  bool get isSliding => _isSliding;

  bool _touching = false;

  bool get touching => _touching;

  Size _pageSize;

  Size get pageSize => _pageSize ?? context.size;

  AnimationController _slideAnimationController;

  AnimationController get slideAnimationController => _slideAnimationController;
  Animation<Offset> _slideOffsetAnimation;

  Animation<Offset> get slideOffsetAnimation => _slideOffsetAnimation;
  Animation<double> _slideScaleAnimation;

  Animation<double> get slideScaleAnimation => _slideScaleAnimation;
  Offset _offset = Offset.zero;

  Offset get offset => _slideAnimationController.isAnimating
      ? _slideOffsetAnimation.value
      : _offset;

  double _scale = 1.0;

  double get scale => _slideAnimationController.isAnimating
      ? slideScaleAnimation.value
      : _scale;
  bool _popping = false;

  SlidePageController get slidePageController {
    assert(mounted, "ExtendedImageSlidePageState is not currently in a tree.");
    return widget.slidePageController;
  }

  @override
  void initState() {
    super.initState();
    _slideAnimationController =
        AnimationController(vsync: this, duration: _defaultSlideBackDuration);
    _slideAnimationController.addListener(_slideAnimation);
    slidePageController?._attachExtendedImageSlidePageState(this);
  }

  void _slideAnimation() {
    if (mounted) {
      setState(() {
        if (_slideAnimationController.isCompleted) _isSliding = false;
      });
    }
    if (widget.slideType == SlideType.onlyImage) {
      slidePageController?._extendedImageGestureState?.slide();
      slidePageController?._extendedImageSlidePageHandlerState?.slide();
    }
    slidePageController?.onSlidingPage?.call(this);
  }

  @override
  void dispose() {
    _slideAnimationController.removeListener(_slideAnimation);
    _slideAnimationController.dispose();
    widget.slidePageController._dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 这部分需要重新考虑下
    if (widget.slideType == SlideType.onlyImage) {
      slidePageController?._extendedImageGestureState?.slide();
      slidePageController?._extendedImageSlidePageHandlerState?.slide();
    }
    _pageSize = MediaQuery.of(context).size;
    Widget result = widget.child;
    if (widget.slideType == SlideType.wholePage) {
      result = Transform.translate(
        offset: offset,
        child: Transform.scale(
          scale: scale,
          child: result,
        ),
      );
    }
    result = slidePageController?.slidePageBackgroundHandler
            ?.call(result, _popping, offset, pageSize) ??
        defaultSlidePageBackgroundHandler(
          child: result,
          isPop: _popping,
          offset: offset,
          pageSize: pageSize,
          color: Theme.of(context).dialogBackgroundColor,
          pageGestureAxis: widget.slideAxis,
        );

//    result = IgnorePointer(
//      ignoring: _isSliding,
//      child: result,
//    );

    return result;
  }

  void _slide(Offset value) {
    if (_slideAnimationController.isAnimating) return;
    _offset = value;
    if (widget.slideAxis == SlideAxis.horizontal) {
      _offset = Offset(value.dx, 0.0);
    } else if (widget.slideAxis == SlideAxis.vertical) {
      _offset = Offset(0.0, value.dy);
    }
    _offset = _handleSlideOffset(_offset);
    _scale = _handleSlideScale(_offset);
    _isSliding = true;
    if (mounted) {
      setState(() {});
    }
    slidePageController?.onSlidingPage?.call(this);
  }

  Offset _handleSlideOffset(Offset offset) =>
      slidePageController?.slideOffsetHandler?.call(offset) ?? offset;

  double _handleSlideScale(Offset offset) {
    return slidePageController?.slideScaleHandler?.call(offset) ??
        defaultSlideScaleHandler(
          offset: offset,
          pageSize: pageSize,
          pageGestureAxis: widget.slideAxis,
        );
  }

  void _animateSlideTo(Offset endOffset, double endScale, Duration duration) {
    if (_slideAnimationController.duration != duration) {
      if (_slideAnimationController.isAnimating) {
        _slideAnimationController.stop();
      }
      _slideAnimationController.duration = duration;
    }
    _slideOffsetAnimation = _slideAnimationController
        .drive(Tween<Offset>(begin: _offset, end: endOffset));
    _slideScaleAnimation = _slideAnimationController
        .drive(Tween<double>(begin: _scale, end: endScale));
    _offset = endOffset;
    _scale = endScale;
    _slideAnimationController.reset();
    _slideAnimationController.forward();
  }

  void _endSlide() {
    if (mounted && _isSliding) {
      var popPage = slidePageController?.slideEndHandler?.call(_offset) ??
          defaultSlideEndHandler(
            offset: _offset,
            pageSize: _pageSize,
            pageGestureAxis: widget.slideAxis,
          );

      if (popPage) {
        setState(() {
          _popping = true;
          _isSliding = false;
        });
        Navigator.pop(context);
      } else {
        var endState = slidePageController?.willSlideBackEndStateHandler
            ?.call(_offset, _scale);

        _animateSlideTo(endState.offset ?? Offset.zero, endState.scale ?? 1.0,
            endState.duration ?? _defaultSlideBackDuration);
      }
    }
  }

  void popPage() {
    setState(() {
      _popping = true;
    });
  }
}

class SlidePageController {
  ExtendedImageSlidePageState _extendedImageSlidePageState;
  ExtendedImageGestureState _extendedImageGestureState;
  ExtendedImageSlidePageHandlerState _extendedImageSlidePageHandlerState;

  ///builder background when slide page
  final SlidePageBackgroundHandler slidePageBackgroundHandler;

  ///customize scale of page when slide page
  final SlideScaleHandler slideScaleHandler;

  ///customize offset when slide page
  final SlideOffsetHandler slideOffsetHandler;

  ///call back of slide end
  ///decide whether pop page
  final SlideEndHandler slideEndHandler;

  /// on sliding page
  final OnSlidingPage onSlidingPage;

  final WillSlideBackEndStateHandler willSlideBackEndStateHandler;

  SlidePageController._default({
    this.slidePageBackgroundHandler,
    this.slideScaleHandler,
    this.slideOffsetHandler,
    this.slideEndHandler,
    this.onSlidingPage,
    this.willSlideBackEndStateHandler,
  });

  SlidePageController({
    this.slidePageBackgroundHandler,
    this.slideScaleHandler,
    this.slideOffsetHandler,
    this.slideEndHandler,
    this.onSlidingPage,
    this.willSlideBackEndStateHandler,
  });

  void _attachExtendedImageSlidePageState(
    final ExtendedImageSlidePageState extendedImageSlidePageState,
  ) {
    this._extendedImageSlidePageState = extendedImageSlidePageState;
  }

  void _attachExtendedImageGestureState(
    final ExtendedImageGestureState _extendedImageGestureState,
  ) {
    this._extendedImageGestureState = _extendedImageGestureState;
  }

  void _attachExtendedImageSlidePageHandlerState(
    final ExtendedImageSlidePageHandlerState extendedImageSlidePageHandlerState,
  ) {
    this._extendedImageSlidePageHandlerState =
        extendedImageSlidePageHandlerState;
  }

  void slideTo([Offset offset]) {
    assert(_extendedImageSlidePageState != null,
        "ExtendedImageSlidePageState is null.");
    _extendedImageSlidePageState._slide(offset ?? Offset.zero);
  }

  void animateSlideTo({
    Offset offset = Offset.zero,
    double scale = 1.0,
    Duration duration = const Duration(milliseconds: 500),
  }) {
    assert(_extendedImageSlidePageState != null,
        "ExtendedImageSlidePageState is null.");
    _extendedImageSlidePageState._animateSlideTo(offset, scale, duration);
  }

  bool get isAnimating =>
      _extendedImageSlidePageState.slideAnimationController.isAnimating;

  double get scale => _extendedImageSlidePageState.scale;

  Offset get offset => _extendedImageSlidePageState.offset;

  bool get isSliding => _extendedImageSlidePageState.isSliding;

  bool get touching => _extendedImageSlidePageState.touching;

  void endSlide() {
    assert(_extendedImageSlidePageState != null,
        "ExtendedImageSlidePageState is null.");
    _extendedImageSlidePageState._endSlide();
  }

  void _dispose() {
    _extendedImageGestureState = null;
    _extendedImageSlidePageHandlerState = null;
    _extendedImageSlidePageState = null;
  }
}

class Sliding {
  double scale;
  Offset offset;
  Duration duration;

  Sliding({
    this.scale = 1.0,
    this.offset = Offset.zero,
    this.duration = _defaultSlideBackDuration,
  });
}
