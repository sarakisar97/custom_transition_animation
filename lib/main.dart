import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as math;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Custom Transition Animation',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const Home(),
    );
  }
}

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with SingleTickerProviderStateMixin {

  List<String> urls = const [
    'https://media.istockphoto.com/photos/mountain-landscape-picture-id517188688?k=20&m=517188688&s=612x612&w=0&h=i38qBm2P-6V4vZVEaMy_TaTEaoCMkYhvLCysE7yJQ5Q=',
    'https://cdn.pixabay.com/photo/2014/02/27/16/10/flowers-276014__340.jpg',
  ];

  late AnimationController _animationController;

  late Animation<double> _zoomAnimation;
  late Animation<double> _fadingAnimation;
  late Animation<Offset> _translateAnimation;

  Offset? _centeredPosition;
  Offset? _position;
  Size? _size;
  int? _index;

  @override
  void initState() {
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _zoomAnimation = Tween(begin: 1.0, end: 2.0).
    animate(CurvedAnimation(parent: _animationController, curve: Curves.fastOutSlowIn))
      ..addListener(() {
        setState(() {});
      });
    _translateAnimation = Tween<Offset>(begin: _position ?? Offset.zero, end: Offset.zero).animate(_animationController)..addListener(() {setState(() {});});
    _fadingAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _animationController, curve: Curves.fastOutSlowIn))..addListener(() {
      setState(() {});
    })..addStatusListener((status) {
      if (status == AnimationStatus.dismissed) {
        _index = null;
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Stack(
          children: [
            Transform(
              transform: Matrix4.diagonal3(math.Vector3(_zoomAnimation.value, _zoomAnimation.value, _zoomAnimation.value)),
              origin: _centeredPosition ?? Offset.zero,
              child: GridView.builder(
                itemCount: urls.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, mainAxisSpacing: 10, crossAxisSpacing: 10),
                itemBuilder: (context, index) {
                  return ImageItem(url: urls[index], onInitialize: (size, position) {
                    _centeredPosition = _getCenteredPosition(position!, size!);
                    _size = size;
                    _position = position;
                  }, onTap: () {
                    _index = index;
                    setState(() {
                      _translateAnimation = Tween<Offset>(begin: _position ?? Offset.zero, end: Offset.zero).animate(_animationController)..addListener(() {setState(() {});});
                    });
                    _animationController.forward();
                  },);
                },
              ),
            ),
            if (_index != null)
              Transform.translate(
                offset: _translateAnimation.value,
                child: FadeTransition(
                  opacity: _fadingAnimation,
                  child: SizedBox(
                    key: Key(_index.toString()),
                    height: _fadingAnimation.drive(Tween(begin: _size!.height, end: MediaQuery.of(context).size.height)).value,
                    width: _fadingAnimation.drive(Tween(begin: _size!.width, end: MediaQuery.of(context).size.width)).value,
                    child: ImageDetails(url: urls[_index!], onBackTapped: () {
                      _animationController.reverse();
                    }),
                  ),
                ),
              ),
          ],
        )
    );
  }

  Offset _getCenteredPosition(Offset position, Size size) {
    final double x = position.dx + size.width / 2;
    final double y = position.dy + size.height / 2;
    return Offset(x, y);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}

class ImageItem extends StatefulWidget {
  const ImageItem({Key? key, required this.onInitialize, required this.onTap, required this.url}) : super(key: key);
  final Function(Size? size, Offset? position) onInitialize;
  final VoidCallback onTap;
  final String url;

  @override
  State<ImageItem> createState() => _ImageItemState();
}

class _ImageItemState extends State<ImageItem> {
  final GlobalKey _globalKey = GlobalKey();
  @override
  Widget build(BuildContext context) {
    return Material(
      child: InkWell(
          onTap: () async{
            final RenderBox? referenceBox = _globalKey.currentContext?.findRenderObject() as RenderBox?;
            final size = referenceBox?.size;
            final position = referenceBox?.localToGlobal(Offset.zero);
            widget.onInitialize(size, position);
            widget.onTap();
          },
          child: Image.network(
              key: _globalKey,
              widget.url
          )
      ),
    );
  }
}

class ImageDetails extends StatelessWidget {
  const ImageDetails({Key? key, required this.url, required this.onBackTapped}) : super(key: key);
  final VoidCallback onBackTapped;
  final String url;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: onBackTapped,
        ),
      ),
      body: SizedBox(
        height: double.infinity,
        child: Image.network(url, fit: BoxFit.cover),
      ),
    );
  }
}




