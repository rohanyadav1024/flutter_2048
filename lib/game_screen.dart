// ignore_for_file: unnecessary_null_comparison, null_closures

import 'dart:math';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_2048game/DefinedColors.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

const Map<int, Color> tilecolor = {
  0: DefinedColor.SILVER,
  2: Color(0xFFEEE4DA),
  4: Color(0xFFEDE0C8),
  8: Color(0xFFF2B179),
  16: Color(0xFFF59563),
  32: Color(0xFFF67C5F),
  64: Color(0xFFF65E3B),
  128: Color(0xFFEDCF72),
  256: Color(0xFFEDCC61),
  512: Color(0xFFEDC850),
  1024: Color(0xFFEDC53F),
  2048: Color(0xFFEDC22E),
};

class Tile {
  final int x;
  final int y;
  int val;

  late Animation<double> animatedX;
  late Animation<double> animatedY;
  late Animation<int> animatedValue;
  late Animation<double> scale;

  Tile(
    this.x,
    this.y,
    this.val,
  ) {
    resetAnimation();
  }

  void resetAnimation() {
    animatedX = AlwaysStoppedAnimation(x.toDouble());
    animatedY = AlwaysStoppedAnimation(y.toDouble());
    animatedValue = AlwaysStoppedAnimation(val);
    scale = AlwaysStoppedAnimation(1.0);
  }

  void moveTo(Animation<double> parent, int x, int y) {
    animatedX = Tween(begin: this.x.toDouble(), end: x.toDouble())
        .animate(CurvedAnimation(parent: parent, curve: Interval(0, .5)));
    animatedY = Tween(begin: this.y.toDouble(), end: y.toDouble())
        .animate(CurvedAnimation(parent: parent, curve: Interval(0, .5)));
  }

  void bounce(Animation<double> parent) {
    scale = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.2), weight: 1.0),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 1.0),
    ]).animate(CurvedAnimation(parent: parent, curve: Interval(.5, 1.0)));
  }

  void appear(Animation<double> parent) {
    scale = Tween(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: parent, curve: Interval(.5, 1.0)));
  }

  void changeNumber(Animation<double> parent, int newValue) {
    animatedValue = TweenSequence([
      TweenSequenceItem(tween: ConstantTween(val), weight: .01),
      TweenSequenceItem(tween: ConstantTween(newValue), weight: 0.99),
    ]).animate(CurvedAnimation(parent: parent, curve: Interval(.5, 1.0)));
  }
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;
  late Animation animation;

  List<List<Tile>> grid =
      List.generate(4, (y) => List.generate(4, (x) => Tile(x, y, 0)));
  Iterable<List<Tile>> get colgrid =>
      List.generate(4, (x) => List.generate(4, (y) => grid[y][x]));
  Iterable<Tile> get plaingrid => grid.expand((e) => e);
  List<Tile> toAdd = [];

  @override
  void initState() {
    super.initState();
    // TODO: implement initState
    controller =
        AnimationController(vsync: this, duration: Duration(milliseconds: 200));
    controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        toAdd.forEach((e) {
          grid[e.y][e.x].val = e.val;
        });
        plaingrid.forEach((element) => element.resetAnimation());
        toAdd.clear();
      }
    });
    grid[3][0].val = 2;
    grid[0][1].val = 4;
    plaingrid.forEach((element) => element.resetAnimation());
  }

  void addTile() {
    List<Tile> emptyList =
        plaingrid.where((element) => element.val == 0).toList();
    emptyList.shuffle();
    toAdd.add(Tile(
        emptyList.first.x, emptyList.first.y, (Random().nextInt(2) + 1) * 2)
      ..appear(controller));
    // toAdd
    //     .add(Tile(emptyList.first.x, emptyList.first.y, 2)..appear(controller));

    // print('tile ${addnewtile.val}');
    // print('${emptyList.first.x} , ${emptyList.first.y} , $randomvalue');
  }

  @override
  Widget build(BuildContext context) {
    double size = MediaQuery.of(context).size.width - 16 * 2;
    double tileSize = (size - 32) / 4;

    List<Widget> gridStack = [];
    gridStack.addAll(plaingrid.map(
      (e) => Positioned(
          left: tileSize * e.x,
          top: tileSize * e.y,
          child: Center(
            child: Container(
              width: tileSize - 8,
              height: tileSize - 8,
              margin: EdgeInsets.only(left: 4.0),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2.0),
                  color: Colors.grey.shade400),
            ),
          )),
    ));

    gridStack.addAll([plaingrid, toAdd]
        .expand((element) => element)
        .map((e) => AnimatedBuilder(
            animation: controller,
            builder: (context, child) => e.animatedValue.value == 0
                ? SizedBox()
                : Positioned(
                    left: tileSize * e.animatedX.value,
                    top: tileSize * e.animatedY.value,
                    child: Container(
                      width: (tileSize - 8) * e.scale.value,
                      height: (tileSize - 8) * e.scale.value,
                      margin: const EdgeInsets.only(left: 4.0),
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2.0),
                          color: tilecolor[e.animatedValue.value]),
                      child: Center(
                          child: Text(
                        '${e.animatedValue.value}',
                        style: TextStyle(
                            color: e.animatedValue.value <= 4
                                ? Colors.grey.shade800
                                : Colors.white,
                            fontSize: 24.0,
                            fontWeight: FontWeight.w700),
                      )),
                    )))));

    return Scaffold(
      body: Container(
        child: Center(
          child: Container(
              width: size,
              height: size,
              padding: EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                  color: Colors.grey, borderRadius: BorderRadius.circular(8.0)),
              child: GestureDetector(
                onHorizontalDragEnd: (details) {
                  toChecktoFull();
                  if (details.velocity.pixelsPerSecond.dx < -500 &&
                      canSwipeLeft()) {
                    doSwipe(swipeLeft);
                  } else if (details.velocity.pixelsPerSecond.dx > 500 &&
                      canSwipeRight()) {
                    doSwipe(swipeRight);
                  }
                },
                onVerticalDragEnd: (details) {
                  toChecktoFull();
                  if (details.velocity.pixelsPerSecond.dy < -250.0 &&
                      canSwipeUp()) {
                    doSwipe(swipeUp);
                  }
                  if (details.velocity.pixelsPerSecond.dy > 250.0 &&
                      canSwipeDown()) {
                    doSwipe(swipeDown);
                  }
                },
                child: Stack(
                  children: gridStack,
                ),
              )),
        ),
      ),
    );
  }

  bool canSwipeLeft() => grid.any(canSwipe);
  bool canSwipeRight() => grid.map((e) => e.reversed.toList()).any(canSwipe);
  bool canSwipeUp() => colgrid.any(canSwipe);
  bool canSwipeDown() => colgrid.map((e) => e.reversed.toList()).any(canSwipe);

  bool canSwipe(List<Tile> tiles) {
    for (var i = 0; i < tiles.length; i++) {
      if (tiles[i].val == 0) {
        if (tiles.skip(i + 1).any((element) => element.val != 0)) {
          return true;
        }
      } else {
        Tile? merge =
            tiles.skip(i + 1).firstWhereOrNull((element) => element.val != 0);
        if (merge != null && merge.val == tiles[i].val) {
          return true;
        }
      }
    }
    return false;
  }

  void swipeLeft() => grid.forEach(mergeTiles);
  void swipeRight() => grid.map((e) => e.reversed.toList()).forEach(mergeTiles);
  void swipeUp() => colgrid.forEach(mergeTiles);
  void swipeDown() =>
      colgrid.map((e) => e.reversed.toList()).forEach(mergeTiles);

  void mergeTiles(List<Tile> tiles) {
    for (var i = 0; i < tiles.length; i++) {
      Iterable<Tile> toCheck =
          tiles.skip(i).skipWhile((value) => value.val == 0);

      if (toCheck.isNotEmpty) {
        Tile t = toCheck.first;
        Tile? mergeTile =
            toCheck.skip(1).firstWhereOrNull((element) => element.val != 0);

        if (mergeTile != null && mergeTile.val != t.val) {
          mergeTile = null;
        }

        if (tiles[i] != t || mergeTile != null) {
          int resultValue = t.val;
          if (mergeTile != null) {
            resultValue += mergeTile.val;
            mergeTile.moveTo(controller, tiles[i].x, tiles[i].y);
            mergeTile.bounce(controller);
            mergeTile.changeNumber(controller, resultValue);
            mergeTile.val = 0;
            t.changeNumber(controller, 0);
          }

          t.val = 0;
          // tiles[i].changeNumber(controller, resultValue);
          tiles[i].val = resultValue;
        }
      }
    }
  }

  void doSwipe(void Function() swipe) {
    setState(() {
      swipe();
      toChecktoFull();
      addTile();
      controller.forward(from: 0);
    });
  }

  bool isFull() {
    if (plaingrid.any((element) => element.val == 0)) return false;
    return true;
  }

  bool possibleSwipe() {
    if (grid.any(canSwipe) ||
        grid.map((e) => e.reversed.toList()).any(canSwipe) ||
        colgrid.any(canSwipe) ||
        colgrid.map((e) => e.reversed.toList()).any(canSwipe)) {
      return true;
    }
    return false;
  }

  void toChecktoFull() {
    //full

    //possible swap
    if (!possibleSwipe()) {
      // grid.clear();
      setState(() {
        showDialog(
          context: context,
          builder: (context) => Center(
            child: Container(
              height: 200,
              width: 200,
              color: Colors.red,
              child: Text(
                'YOU LOSE',
              ),
            ),
          ),
        );
      });
    }
    return;
  }
}
