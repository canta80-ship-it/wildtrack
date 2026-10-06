class RadarProfile {
  const RadarProfile(this.latin, this.cycle, this.habitats, {this.peak = const {}, this.months = const {}, this.alpine = false, this.localised = false, this.dormant = const {}, this.audible = false, this.common = false, this.urbanGreen = false});
  final String latin, cycle;
  final Set<String> habitats;
  final Set<int> peak, months, dormant;
  final bool alpine, localised, audible, common, urbanGreen;
}
// Editorial compatibility profiles, not calibrated probabilities or range maps.
const radarProfiles = <String, RadarProfile>{
 'Riccio': RadarProfile('Erinaceus europaeus','nocturnal',{'forest','meadow','farmland','park','scrub'},common:true,urbanGreen:true,dormant:{12,1,2}),
 'Gallo cedrone': RadarProfile('Tetrao urogallus','diurnal',{'forest'},alpine:true,localised:true,peak:{4,5},audible:true),
 'Gallo forcello': RadarProfile('Lyrurus tetrix','crepuscular',{'forest','meadow','scrub'},alpine:true,localised:true,peak:{4,5},audible:true),
 'Lince': RadarProfile('Lynx lynx','nocturnal',{'forest'},localised:true,peak:{2,3}),
 'Tritone': RadarProfile('Ichthyosaura alpestris','nocturnal',{'stillwater','wetland','forest'},peak:{3,4,5,6},dormant:{12,1,2}),
 'Rospo': RadarProfile('Bufo bufo','nocturnal',{'water','wetland','forest','park'},peak:{3,4,5},dormant:{12,1,2},common:true,urbanGreen:true),
 'Salamandra': RadarProfile('Salamandra salamandra','nocturnal',{'forest'},peak:{3,4,5,9,10},dormant:{12,1,2}),
 'Cervo': RadarProfile('Cervus elaphus','crepuscular',{'forest','meadow'},localised:true,peak:{9,10}),
 'Capriolo': RadarProfile('Capreolus capreolus','crepuscular',{'forest','meadow','farmland'},peak:{4,5,6,7},common:true),
 'Volpe': RadarProfile('Vulpes vulpes','crepuscular',{'forest','meadow','farmland','park','scrub'},common:true,urbanGreen:true),
 'Camoscio alpino': RadarProfile('Rupicapra rupicapra','crepuscular',{'rock','meadow','forest'},alpine:true,peak:{5,6,9,10,11}),
 'Stambecco': RadarProfile('Capra ibex','diurnal',{'rock','meadow'},alpine:true),
 'Cinghiale': RadarProfile('Sus scrofa','nocturnal',{'forest','farmland','scrub'}),
 'Aquila reale': RadarProfile('Aquila chrysaetos','diurnal',{'rock','meadow'},localised:true),
 'Grifone': RadarProfile('Gyps fulvus','diurnal',{'rock','meadow'},localised:true),
 'Poiana': RadarProfile('Buteo buteo','diurnal',{'meadow','farmland','forest'},common:true),
 'Allocco': RadarProfile('Strix aluco','nocturnal',{'forest','park'},audible:true,peak:{1,2,3,10,11},common:true,urbanGreen:true),
 'Picchio nero': RadarProfile('Dryocopus martius','diurnal',{'forest'},audible:true,peak:{2,3,4,5}),
 'Airone cenerino': RadarProfile('Ardea cinerea','diurnal',{'water','wetland','farmland'},common:true),
 'Germano reale': RadarProfile('Anas platyrhynchos','diurnal',{'water','wetland'},audible:true,common:true),
 'Falco di palude': RadarProfile('Circus aeruginosus','diurnal',{'wetland','water'},localised:true),
 'Orso bruno': RadarProfile('Ursus arctos','crepuscular',{'forest','meadow','farmland'},localised:true,dormant:{12,1,2},peak:{4,5,9,10}),
 'Lupo': RadarProfile('Canis lupus','nocturnal',{'forest','meadow','rock'},localised:true,audible:true),
 'Sciacallo dorato': RadarProfile('Canis aureus','nocturnal',{'scrub','forest','farmland'},localised:true,audible:true),
 'Marmotta': RadarProfile('Marmota marmota','diurnal',{'meadow','rock'},alpine:true,dormant:{10,11,12,1,2,3,4},audible:true),
 'Ermellino': RadarProfile('Mustela erminea','diurnal',{'meadow','rock','forest','scrub','wetland'},localised:true),
 'Tasso': RadarProfile('Meles meles','nocturnal',{'forest','farmland','meadow'},common:true),
 'Gracchio alpino': RadarProfile('Pyrrhocorax graculus','diurnal',{'rock','meadow'},localised:true,audible:true),
 'Gufo reale': RadarProfile('Bubo bubo','nocturnal',{'rock'},localised:true,audible:true,peak:{1,2,3}),
 'Barbagianni': RadarProfile('Tyto alba','nocturnal',{'farmland','meadow','urban'},audible:true,common:true),
 'Ghiandaia': RadarProfile('Garrulus glandarius','diurnal',{'forest','park'},audible:true,peak:{9,10},common:true,urbanGreen:true),
 'Lepre': RadarProfile('Lepus europaeus','crepuscular',{'farmland','meadow'},peak:{3,4,5},common:true),
 'Scoiattolo': RadarProfile('Sciurus vulgaris','diurnal',{'forest','park'},peak:{3,4,9,10},common:true,urbanGreen:true),
 'Upupa': RadarProfile('Upupa epops','diurnal',{'farmland','meadow','park'},months:{3,4,5,6,7,8,9},peak:{4,5,6},audible:true,common:true),
 'Gheppio': RadarProfile('Falco tinnunculus','diurnal',{'farmland','meadow','rock','urban'},common:true,urbanGreen:true),
 'Assiolo': RadarProfile('Otus scops','nocturnal',{'farmland','park','scrub'},months:{3,4,5,6,7,8,9},peak:{5,6,7},audible:true,common:true,urbanGreen:true),
 'Nibbio reale': RadarProfile('Milvus milvus','diurnal',{'farmland','meadow','forest'},localised:true),
 'Nibbio bruno': RadarProfile('Milvus migrans','diurnal',{'water','wetland','farmland','forest'},months:{3,4,5,6,7,8,9},peak:{4,5,6},localised:true),
};
