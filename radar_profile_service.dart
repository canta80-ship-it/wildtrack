class RadarProfile {
  const RadarProfile(this.latin, this.cycle, this.habitats, {this.peak = const {}, this.months = const {}, this.alpine = false, this.localised = false, this.dormant = const {}, this.audible = false});
  final String latin, cycle;
  final Set<String> habitats;
  final Set<int> peak, months, dormant;
  final bool alpine, localised, audible;
}
// Editorial compatibility profiles, not calibrated probabilities or range maps.
const radarProfiles = <String, RadarProfile>{
 'Lince': RadarProfile('Lynx lynx','nocturnal',{'forest'},localised:true,peak:{2,3}),
 'Tritone': RadarProfile('Ichthyosaura alpestris','nocturnal',{'water','wetland','forest'},peak:{3,4,5,6},dormant:{12,1,2}),
 'Rospo': RadarProfile('Bufo bufo','nocturnal',{'water','wetland','forest','park'},peak:{3,4,5},dormant:{12,1,2}),
 'Salamandra': RadarProfile('Salamandra salamandra','nocturnal',{'forest','stream'},peak:{3,4,5,9,10},dormant:{12,1,2}),
 'Cervo': RadarProfile('Cervus elaphus','crepuscular',{'forest','meadow'},peak:{9,10}),
 'Capriolo': RadarProfile('Capreolus capreolus','crepuscular',{'forest','meadow','farmland'},peak:{4,5,6,7}),
 'Volpe': RadarProfile('Vulpes vulpes','crepuscular',{'forest','meadow','farmland','urban'}),
 'Camoscio alpino': RadarProfile('Rupicapra rupicapra','crepuscular',{'rock','meadow','forest'},alpine:true,peak:{5,6,9,10,11}),
 'Stambecco': RadarProfile('Capra ibex','diurnal',{'rock','meadow'},alpine:true),
 'Cinghiale': RadarProfile('Sus scrofa','nocturnal',{'forest','farmland','scrub'}),
 'Aquila reale': RadarProfile('Aquila chrysaetos','diurnal',{'rock','meadow'},localised:true),
 'Grifone': RadarProfile('Gyps fulvus','diurnal',{'rock','meadow'},localised:true),
 'Poiana': RadarProfile('Buteo buteo','diurnal',{'meadow','farmland','forest'}),
 'Allocco': RadarProfile('Strix aluco','nocturnal',{'forest','park'},audible:true,peak:{1,2,3,10,11}),
 'Picchio nero': RadarProfile('Dryocopus martius','diurnal',{'forest'},audible:true,peak:{2,3,4,5}),
 'Airone cenerino': RadarProfile('Ardea cinerea','diurnal',{'water','wetland','farmland'}),
 'Germano reale': RadarProfile('Anas platyrhynchos','diurnal',{'water','wetland'},audible:true),
 'Falco di palude': RadarProfile('Circus aeruginosus','diurnal',{'wetland','water'},localised:true),
 'Orso bruno': RadarProfile('Ursus arctos','crepuscular',{'forest','meadow','farmland'},localised:true,dormant:{12,1,2},peak:{4,5,9,10}),
 'Lupo': RadarProfile('Canis lupus','nocturnal',{'forest','meadow','rock'},localised:true,audible:true),
 'Sciacallo dorato': RadarProfile('Canis aureus','nocturnal',{'scrub','forest','farmland'},localised:true,audible:true),
 'Marmotta': RadarProfile('Marmota marmota','diurnal',{'meadow','rock'},alpine:true,dormant:{10,11,12,1,2,3,4},audible:true),
 'Ermellino': RadarProfile('Mustela erminea','diurnal',{'meadow','rock','forest','scrub','wetland'},localised:true),
 'Tasso': RadarProfile('Meles meles','nocturnal',{'forest','farmland','meadow'}),
 'Gracchio alpino': RadarProfile('Pyrrhocorax graculus','diurnal',{'rock','meadow'},localised:true,audible:true),
 'Gufo reale': RadarProfile('Bubo bubo','nocturnal',{'rock'},localised:true,audible:true,peak:{1,2,3}),
 'Barbagianni': RadarProfile('Tyto alba','nocturnal',{'farmland','meadow','urban'},audible:true),
 'Ghiandaia': RadarProfile('Garrulus glandarius','diurnal',{'forest','park'},audible:true,peak:{9,10}),
 'Lepre': RadarProfile('Lepus europaeus','crepuscular',{'farmland','meadow'},peak:{3,4,5}),
 'Scoiattolo': RadarProfile('Sciurus vulgaris','diurnal',{'forest','park'},peak:{3,4,9,10}),
 'Upupa': RadarProfile('Upupa epops','diurnal',{'farmland','meadow','park'},months:{3,4,5,6,7,8,9},peak:{4,5,6},audible:true),
 'Gheppio': RadarProfile('Falco tinnunculus','diurnal',{'farmland','meadow','rock','urban'}),
 'Assiolo': RadarProfile('Otus scops','nocturnal',{'farmland','park','scrub'},months:{3,4,5,6,7,8,9},peak:{5,6,7},audible:true),
 'Nibbio reale': RadarProfile('Milvus milvus','diurnal',{'farmland','meadow','forest'},localised:true),
 'Nibbio bruno': RadarProfile('Milvus migrans','diurnal',{'water','wetland','farmland','forest'},months:{3,4,5,6,7,8,9},peak:{4,5,6},localised:true),
};
