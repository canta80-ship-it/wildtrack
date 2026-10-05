class RadarProfile {
  const RadarProfile(this.latin, this.cycle, this.habitats, {this.peak = const {}, this.months = const {}, this.minAltitude = -100, this.maxAltitude = 3000, this.alpine = false, this.localised = false, this.dormant = const {}, this.audible = false});
  final String latin, cycle;
  final Set<String> habitats;
  final Set<int> peak, months, dormant;
  final double minAltitude, maxAltitude;
  final bool alpine, localised, audible;
}
// Editorial compatibility profiles, not calibrated probabilities or range maps.
const radarProfiles = <String, RadarProfile>{
 'Lince': RadarProfile('Lynx lynx','nocturnal',{'forest','rock'},localised:true,peak:{2,3}),
 'Tritone': RadarProfile('Ichthyosaura alpestris','nocturnal',{'water','wetland','forest'},peak:{3,4,5,6},dormant:{12,1,2}),
 'Rospo': RadarProfile('Bufo bufo','nocturnal',{'water','wetland','forest','park'},peak:{3,4,5},dormant:{12,1,2}),
 'Salamandra': RadarProfile('Salamandra salamandra','nocturnal',{'forest','water'},peak:{3,4,5,9,10},dormant:{12,1,2}),
 'Cervo': RadarProfile('Cervus elaphus','crepuscular',{'forest','meadow'},peak:{9,10},maxAltitude:2400),
 'Capriolo': RadarProfile('Capreolus capreolus','crepuscular',{'forest','meadow','farmland'},peak:{4,5,6,7},maxAltitude:2200),
 'Volpe': RadarProfile('Vulpes vulpes','crepuscular',{'forest','meadow','farmland','urban'},maxAltitude:2800),
 'Camoscio alpino': RadarProfile('Rupicapra rupicapra','crepuscular',{'rock','meadow','forest'},minAltitude:500,alpine:true,peak:{5,6,9,10,11}),
 'Stambecco': RadarProfile('Capra ibex','diurnal',{'rock','meadow'},minAltitude:1200,maxAltitude:3500,alpine:true),
 'Cinghiale': RadarProfile('Sus scrofa','nocturnal',{'forest','farmland','scrub'},maxAltitude:2000),
 'Aquila reale': RadarProfile('Aquila chrysaetos','diurnal',{'rock','meadow'},localised:true,maxAltitude:3500),
 'Grifone': RadarProfile('Gyps fulvus','diurnal',{'rock','meadow'},localised:true),
 'Poiana': RadarProfile('Buteo buteo','diurnal',{'meadow','farmland','forest'},maxAltitude:2400),
 'Allocco': RadarProfile('Strix aluco','nocturnal',{'forest','park'},audible:true,maxAltitude:2000,peak:{1,2,3,10,11}),
 'Picchio nero': RadarProfile('Dryocopus martius','diurnal',{'forest'},audible:true,peak:{2,3,4,5},maxAltitude:2400),
 'Airone cenerino': RadarProfile('Ardea cinerea','diurnal',{'water','wetland','farmland'},maxAltitude:1800),
 'Germano reale': RadarProfile('Anas platyrhynchos','diurnal',{'water','wetland'},audible:true,maxAltitude:2200),
 'Falco di palude': RadarProfile('Circus aeruginosus','diurnal',{'wetland','water','meadow'},localised:true,maxAltitude:1000),
 'Orso bruno': RadarProfile('Ursus arctos','crepuscular',{'forest','meadow'},localised:true,dormant:{12,1,2},peak:{4,5,9,10},maxAltitude:2600),
 'Lupo': RadarProfile('Canis lupus','nocturnal',{'forest','meadow','rock'},localised:true,audible:true),
 'Sciacallo dorato': RadarProfile('Canis aureus','nocturnal',{'scrub','forest','farmland'},localised:true,audible:true,maxAltitude:1200),
 'Marmotta': RadarProfile('Marmota marmota','diurnal',{'meadow','rock'},alpine:true,minAltitude:1000,dormant:{10,11,12,1,2,3,4},audible:true),
 'Ermellino': RadarProfile('Mustela erminea','diurnal',{'meadow','rock','forest'},maxAltitude:3300,localised:true),
 'Tasso': RadarProfile('Meles meles','nocturnal',{'forest','farmland','meadow'},maxAltitude:2200),
 'Gracchio alpino': RadarProfile('Pyrrhocorax graculus','diurnal',{'rock','meadow'},alpine:true,minAltitude:1000,maxAltitude:4000,audible:true),
 'Gufo reale': RadarProfile('Bubo bubo','nocturnal',{'rock','forest','meadow'},localised:true,audible:true,peak:{1,2,3}),
 'Barbagianni': RadarProfile('Tyto alba','nocturnal',{'farmland','meadow','urban'},audible:true,maxAltitude:1200),
 'Ghiandaia': RadarProfile('Garrulus glandarius','diurnal',{'forest','park'},audible:true,peak:{9,10},maxAltitude:2200),
 'Lepre': RadarProfile('Lepus europaeus','crepuscular',{'farmland','meadow'},maxAltitude:2200,peak:{3,4,5}),
 'Scoiattolo': RadarProfile('Sciurus vulgaris','diurnal',{'forest','park'},maxAltitude:2300,peak:{3,4,9,10}),
 'Upupa': RadarProfile('Upupa epops','diurnal',{'farmland','meadow','park'},months:{3,4,5,6,7,8,9},peak:{4,5,6},maxAltitude:1300,audible:true),
 'Gheppio': RadarProfile('Falco tinnunculus','diurnal',{'farmland','meadow','rock','urban'},maxAltitude:2800),
 'Assiolo': RadarProfile('Otus scops','nocturnal',{'farmland','park','scrub'},months:{3,4,5,6,7,8,9},peak:{5,6,7},maxAltitude:1600,audible:true),
 'Nibbio reale': RadarProfile('Milvus milvus','diurnal',{'farmland','meadow','forest'},localised:true,maxAltitude:1800),
 'Nibbio bruno': RadarProfile('Milvus migrans','diurnal',{'water','wetland','farmland','forest'},months:{3,4,5,6,7,8,9},peak:{4,5,6},localised:true,maxAltitude:1500),
};
