import 'package:flutter/material.dart';

/// Vector plates stay sharp at every screen density and work offline.
class SpeciesSignIllustration extends StatelessWidget {
  const SpeciesSignIllustration({super.key, required this.species, required this.index, required this.label});
  final String species, label;
  final int index;
  @override Widget build(BuildContext context) => Semantics(label:'$species: $label · illustrazione indicativa',image:true,
    child:SizedBox(height:100,child:CustomPaint(painter:_SignPainter(species,index),size:const Size(100,100))));
}
class _SignPainter extends CustomPainter {
  _SignPainter(this.species,this.index);
  final String species;
  final int index;
  @override void paint(Canvas canvas,Size size){
    canvas.save();canvas.scale(size.width/100,size.height/100);
    final dark=Paint()..color=const Color(0xFF334B3E);
    final ochre=Paint()..color=const Color(0xFFB99554);
    final ink=Paint()..color=const Color(0xFF263B32)..style=PaintingStyle.stroke..strokeWidth=1.8..strokeCap=StrokeCap.round;
    canvas.drawOval(const Rect.fromLTWH(8,78,84,9),Paint()..color=const Color(0xFFE1DBCB));
    if(species=='Lince' && index==0){
      canvas.drawPath(Path()..moveTo(26,63)..cubicTo(26,48,39,43,48,51)..cubicTo(63,41,77,53,73,66)..cubicTo(60,75,38,76,26,63)..close(),dark);
      for(final p in [const Offset(22,40),const Offset(39,28),const Offset(59,28),const Offset(77,41)])canvas.drawOval(Rect.fromCenter(center:p,width:14,height:19),dark);
    }else if(species=='Lince' && index==1){
      for(var i=0;i<3;i++)canvas.drawOval(Rect.fromLTWH(18+i*20,48+(i%2)*4,29,17),Paint()..color=const Color(0xFF78664B));
    }else if(species=='Lince' && index==2){
      canvas.drawPath(Path()..moveTo(26,70)..quadraticBezierTo(20,30,39,22)..lineTo(56,69)..close(),ochre);
      for(var i=0;i<5;i++)canvas.drawLine(Offset(37.0+i*2,28),Offset(35.0+i*3,9.0+i*2),ink);
    }else if(index==2 && species=='Rospo'){
      for(var j=0;j<2;j++){
        final path=Path()..moveTo(13,37.0+j*19)..cubicTo(30,10.0+j*19,63,65.0+j*19,87,40.0+j*19);
        canvas.drawPath(path,Paint()..color=const Color(0xFFCFD8C4)..style=PaintingStyle.stroke..strokeWidth=10);
        for(var i=0;i<8;i++)canvas.drawCircle(Offset(16.0+i*10,37.0+j*19+((i%3)-1)*5),2.7,dark);
      }
    }else if(index==3 && species=='Salamandra'){
      canvas.drawPath(Path()..moveTo(10,70)..lineTo(30,49)..lineTo(85,43)..lineTo(90,59)..lineTo(28,78)..close(),Paint()..color=const Color(0xFF80694B));
      for(var i=0;i<4;i++)canvas.drawOval(Rect.fromCenter(center:Offset(20.0+i*19,80-i*2.0),width:25,height:12),ochre);
    }else if(index==1 && species=='Rospo'){
      canvas.drawOval(const Rect.fromLTWH(19,31,63,41),ochre);
      canvas.drawOval(const Rect.fromLTWH(29,38,43,25),Paint()..color=const Color(0xFFD1A566));
      canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(34,48,35,6),const Radius.circular(3)),dark);
    }else if(index==2 && species=='Tritone'){
      canvas.drawPath(Path()..moveTo(16,75)..quadraticBezierTo(31,33,42,20)..quadraticBezierTo(50,63,16,75)..close(),Paint()..color=const Color(0xFF7D9B64));
      canvas.drawOval(const Rect.fromLTWH(34,43,14,19),Paint()..color=const Color(0xFFC9B885));
      canvas.drawCircle(const Offset(41,52),3,dark);
    }else if(index==3 && species=='Rospo'){
      canvas.drawOval(const Rect.fromLTWH(21,30,38,43),dark);
      canvas.drawPath(Path()..moveTo(52,60)..cubicTo(71,77,89,71,91,39),Paint()..color=const Color(0xFF334B3E)..style=PaintingStyle.stroke..strokeWidth=6..strokeCap=StrokeCap.round);
      canvas.drawCircle(const Offset(30,39),2,ochre);canvas.drawCircle(const Offset(48,39),2,ochre);
    }else if((index==2 && species=='Salamandra') || (index==3 && species!='Lince')){
      canvas.drawOval(const Rect.fromLTWH(32,33,24,39),Paint()..color=const Color(0xFF7C8C76));
      canvas.drawCircle(const Offset(44,27),10,dark);
      canvas.drawPath(Path()..moveTo(44,65)..quadraticBezierTo(73,82,86,54),ink);
      for(var i=0;i<3;i++){canvas.drawLine(Offset(36,26.0+i*4),Offset(23,17.0+i*7),ochre..strokeWidth=2);canvas.drawLine(Offset(53,26.0+i*4),Offset(66,17.0+i*7),ochre);}
    }else if(species=='Lince'){
      canvas.drawPath(Path()..moveTo(25,24)..cubicTo(27,61,68,40,69,66),Paint()..color=const Color(0xFFB99554)..style=PaintingStyle.stroke..strokeWidth=17..strokeCap=StrokeCap.round);
      canvas.drawCircle(const Offset(69,66),9,dark);
    }else{
      final color=species=='Salamandra'?const Color(0xFF26392F):species=='Rospo'?const Color(0xFF947B55):const Color(0xFF587D83);
      canvas.drawOval(species=='Rospo'?const Rect.fromLTWH(22,30,57,44):const Rect.fromLTWH(31,22,26,50),Paint()..color=color);
      canvas.drawCircle(const Offset(44,24),12,Paint()..color=color);
      if(species!='Rospo')canvas.drawPath(Path()..moveTo(44,66)..cubicTo(58,82,78,78,79,57),Paint()..color=color..style=PaintingStyle.stroke..strokeWidth=9..strokeCap=StrokeCap.round);
      for(final p in [const Offset(32,38),const Offset(56,38),const Offset(32,62),const Offset(55,62)]){canvas.drawLine(p,Offset(p.dx<45?p.dx-14:p.dx+14,p.dy+8),ink);}
      if(species=='Salamandra'){for(final p in [const Offset(40,31),const Offset(49,46),const Offset(39,61),const Offset(68,74)])canvas.drawOval(Rect.fromCenter(center:p,width:8,height:13),Paint()..color=const Color(0xFFE3C849));}
      if(species=='Rospo'){for(var i=0;i<12;i++)canvas.drawCircle(Offset(30+(i%4)*11.0,40+(i~/4)*10.0),2,ochre);}
      if(species=='Tritone' && index==0)canvas.drawOval(const Rect.fromLTWH(36,33,17,32),Paint()..color=const Color(0xFFCC8038));
    }
    canvas.restore();
  }
  @override bool shouldRepaint(covariant _SignPainter old)=>old.species!=species || old.index!=index;
}
