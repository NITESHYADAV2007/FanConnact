const fs = require("fs");
const path = require("path");

// ─── SPORT CONFIGS (same as server.js) ──────────────────────────────────────

const SPORTS_CONFIG = {
  cricket: {
    defaultCategory: "odi_bat_men",
    categoryKeys: [
      "odi_bat_men","odi_bowl_men","odi_ar_men","odi_bat_women","odi_bowl_women","odi_ar_women",
      "t20_bat_men","t20_bowl_men","t20_ar_men","t20_bat_women","t20_bowl_women","t20_ar_women",
      "test_bat_men","test_bowl_men","test_ar_men"
    ]
  },
  football: {
    defaultCategory: "scorers_men",
    categoryKeys: ["scorers_men","assists_men","rating_men","scorers_women","assists_women","rating_women"]
  },
  basketball: {
    defaultCategory: "points",
    categoryKeys: ["points","rebounds","assists"]
  },
  tennis: {
    defaultCategory: "atp_singles",
    categoryKeys: ["atp_singles","atp_doubles","wta_singles","wta_doubles"]
  },
  baseball: {
    defaultCategory: "hr",
    categoryKeys: ["hr","avg","rbi","ops"]
  },
  hockey: {
    defaultCategory: "goals_men",
    categoryKeys: ["goals_men","assists_men","goals_women","assists_women"]
  },
  volleyball: {
    defaultCategory: "points_men",
    categoryKeys: ["points_men","spikes_men","blocks_men","points_women","spikes_women","blocks_women"]
  },
  kabbaddi: {
    defaultCategory: "raid",
    categoryKeys: ["raid","tackle","allround"]
  },
  "e-sports": {
    defaultCategory: "earnings",
    categoryKeys: ["all","valorant","lol","cs2","dota2"]
  },
  "table-tennis": {
    defaultCategory: "singles_men",
    categoryKeys: ["singles_men","doubles_men","singles_women","doubles_women"]
  }
};

// ─── DATA ARRAYS (same as server.js) ────────────────────────────────────────

const CRICKET_RAW = {
  "odi_bat_men": [
    ["Shubman Gill","India",784,50,2876,0,58.2,102.3],
    ["Babar Azam","Pakistan",766,125,5934,0,56.8,89.4],
    ["Rohit Sharma","India",756,267,10866,0,48.9,90.2],
    ["Virat Kohli","India",736,295,13906,0,57.3,93.2],
    ["Daryl Mitchell","New Zealand",720,45,1983,12,52.6,96.1],
    ["Ibrahim Zadran","Afghanistan",715,38,1756,0,50.1,85.3],
    ["KL Rahul","India",708,86,3614,0,48.5,88.7],
    ["Rassie van der Dussen","South Africa",702,56,2467,0,52.8,87.9],
    ["Pathum Nissanka","Sri Lanka",695,52,2234,0,46.2,85.6],
    ["Harry Tector","Ireland",688,52,2198,0,47.8,89.4],
    ["Shai Hope","West Indies",680,132,4789,0,44.6,80.5],
    ["Travis Head","Australia",675,78,3124,21,42.8,98.7],
    ["Kane Williamson","New Zealand",670,170,7046,12,48.2,81.3],
    ["Steve Smith","Australia",665,158,6321,8,43.7,86.9],
    ["Heinrich Klaasen","South Africa",660,52,1965,0,45.3,106.2],
    ["Joe Root","England",655,178,7432,28,51.3,85.6],
    ["Fakhar Zaman","Pakistan",650,95,3954,0,45.6,92.3],
    ["Rahmanullah Gurbaz","Afghanistan",645,40,1765,0,44.8,91.5],
    ["Suryakumar Yadav","India",640,62,2254,0,44.2,104.3],
    ["Quinton de Kock","South Africa",635,155,6743,0,45.8,96.2],
    ["David Warner","Australia",630,165,6932,0,44.6,95.3],
    ["Temba Bavuma","South Africa",625,52,2387,0,48.6,84.2],
    ["Charith Asalanka","Sri Lanka",618,58,2187,28,44.8,90.5],
    ["Litton Das","Bangladesh",615,92,3654,0,43.2,87.6],
    ["Mohammad Rizwan","Pakistan",610,86,3165,0,42.8,86.3],
    ["Aiden Markram","South Africa",605,72,2786,14,43.8,91.2],
    ["Ben Stokes","England",600,118,3578,82,41.6,96.4],
    ["Jonny Bairstow","England",595,106,3856,0,43.2,98.7],
    ["Glenn Maxwell","Australia",590,142,3654,72,37.8,102.3],
    ["Sean Williams","Zimbabwe",585,56,2104,52,45.2,84.6]
  ]
};

const CRICKET_NAMES = ["Virat Kohli","Babar Azam","Rohit Sharma","Shubman Gill","Travis Head","Suryakumar Yadav","Heinrich Klaasen","KL Rahul","Pathum Nissanka","Rassie van der Dussen","Daryl Mitchell","Shai Hope","Rahmanullah Gurbaz","Harry Tector","Devon Conway","Glenn Maxwell","Ben Stokes","Mohammad Rizwan","Litton Das","David Warner","Steve Smith","Marnus Labuschagne","Joe Root","Kane Williamson","Jonny Bairstow","Temba Bavuma","Aiden Markram","Quinton de Kock","Fakhar Zaman","Imam-ul-Haq","Kusal Mendis","Charith Asalanka","Sadeera Samarawickrama","Brandon King","Nicholas Pooran","Sherfane Rutherford","Johnson Charles","Sean Williams","Sikandar Raza","Craig Ervine","Paul Stirling","Andy Balbirnie","Lorcan Tucker","Curtis Campher","George Dockrell","Scott Edwards","Max ODowd","Bas de Leede","Vikramjit Singh","Michael van Lingen","Gerhard Erasmus","David Wiese","JJ Smit","Ruben Trumpelmann","Bernard Scholtz","Tom Latham","Will Young","Rachin Ravindra","Glenn Phillips","Finn Allen","Mark Chapman","Tim Seifert","Joshua Little","Sam Curran","Moeen Ali","Chris Woakes","Dawid Malan","Jason Roy","Alex Hales","David Malan","James Vince","Sam Billings","Tom Banton","Daniel Bell-Drummond","Joe Clarke","Sam Hain","Adam Hose","Rob Yates","Mandeep Singh","Manish Pandey","Suresh Raina","MS Dhoni","Yuvraj Singh","Gautam Gambhir","Virender Sehwag","Sachin Tendulkar","Ricky Ponting","Adam Gilchrist","Matthew Hayden","Chris Gayle","Brian Lara","Viv Richards","Gordon Greenidge","Desmond Haynes","Jacques Kallis","Hashim Amla","AB de Villiers","Graeme Smith","Herschelle Gibbs","Kumar Sangakkara","Mahela Jayawardene","Sanath Jayasuriya","Tillakaratne Dilshan","Ross Taylor","Stephen Fleming","Brendon McCullum","Martin Crowe"];
const CRICKET_COUNTRIES = ["India","Australia","England","New Zealand","South Africa","Pakistan","Sri Lanka","West Indies","Bangladesh","Afghanistan","Zimbabwe","Ireland","Netherlands","Namibia","Scotland"];
const CRICKET_COUNTRIES_W = ["Australia","England","India","New Zealand","South Africa","West Indies","Sri Lanka","Pakistan","Bangladesh","Ireland","Netherlands","Scotland","Thailand","Zimbabwe","PNG"];

const FOOTBALL_NAMES = ["Erling Haaland","Kylian Mbappe","Harry Kane","Lionel Messi","Cristiano Ronaldo","Mohamed Salah","Robert Lewandowski","Karim Benzema","Kevin De Bruyne","Neymar","Vinicius Jr","Jude Bellingham","Rodri","Antoine Griezmann","Bukayo Saka","Phil Foden","Jamal Musiala","Lautaro Martinez","Victor Osimhen","Rafael Leao","Bernardo Silva","Pedri","Eden Hazard","Luka Modric","Toni Kroos","Joshua Kimmich","Declan Rice","Martin Odegaard","Bruno Fernandes","Marcus Rashford","Gabriel Jesus","Jack Grealish","Mason Mount","Kai Havertz","Christopher Nkunku","Florian Wirtz","Serge Gnabry","Thomas Muller","Leroy Sane","Alphonso Davies","Kylian Mbappe Lottin","Ousmane Dembele","Randal Kolo Muani","Marcus Thuram","Olivier Giroud","Kingsley Coman","Mike Maignan","Gianluigi Donnarumma","Alessandro Bastoni","Theo Hernandez","Federico Valverde","Aurelien Tchouameni","Eduardo Camavinga","Rodrygo Goes","Endrick","Lamine Yamal","Pau Cubarsi","Warren Zaire-Emery","Xavi Simons","Arda Guler","Khvicha Kvaratskhelia","Rasmus Hojlund","Darwin Nunez","Luis Diaz","Cody Gakpo","Dominik Szoboszlai","Virgil van Dijk","Trent Alexander-Arnold","Andrew Robertson","Alisson Becker","Ederson","Ruben Dias","Joao Cancelo","Bernardo Silva","Erling Haaland","Jeremy Doku","Julian Alvarez","Julian Brandt","Karim Adeyemi","Donyell Malen","Matthijs de Ligt","Frenkie de Jong","Memphis Depay","Dusan Vlahovic","Federico Chiesa","Nicolo Barella","Lautaro Martinez","Romelu Lukaku","Kevin De Bruyne","Youri Tielemans","Jeremy Doku","Romeo Lavia","Dominic Calvert-Lewin","James Maddison","Son Heung-min","Richarlison","Dejan Kulusevski","Pedro Porro","Cristian Romero","Heung-min Son","Min-jae Kim","Wataru Endo","Takefusa Kubo","Daichi Kamada"];
const FOOTBALL_TEAMS = ["Manchester City","Real Madrid","Bayern Munich","PSG","Liverpool","Barcelona","Arsenal","Inter Milan","AC Milan","Juventus","Chelsea","Tottenham","Manchester United","Atletico Madrid","Borussia Dortmund","RB Leipzig","Napoli","Benfica","Porto","Ajax","Sporting CP","Marseille","Lyon","Roma","Lazio","Feyenoord","PSV","Celtic","Rangers","Club Brugge"];
const FOOTBALL_POSITIONS = ["FW","FW","MF","FW","MF","FW","MF","DF","GK","FW","MF","DF","MF","FW","MF"];
const FOOTBALL_COUNTRIES = ["Norway","France","England","Argentina","Portugal","Egypt","Poland","France","Belgium","Brazil","Brazil","England","Spain","France","England","England","Germany","Argentina","Nigeria","Portugal","Portugal","Spain","Belgium","Croatia","Germany","Germany","England","Norway","Portugal","England","Brazil","England","England","Germany","France","Germany","Germany","Germany","Germany","Canada","France","France","France","France","France","France","Italy","Italy","Italy","France","Spain","France","France","Brazil","Brazil","Spain","Spain","France","Netherlands","Turkey","Georgia","Denmark","Uruguay","Colombia","Netherlands","Hungary","Netherlands","England","Scotland","Brazil","Brazil","Portugal","Belgium","Portugal","Netherlands","Belgium","Portugal","Germany","Germany","Netherlands","Netherlands","Netherlands","Serbia","Italy","Italy","Argentina","Belgium","Belgium","Belgium","Belgium","England","England","South Korea","Brazil","Sweden","Spain","Argentina","South Korea","South Korea","Japan","Japan","Japan"];

const TENNIS_ATP = ["Jannik Sinner","Novak Djokovic","Carlos Alcaraz","Daniil Medvedev","Alexander Zverev","Andrey Rublev","Stefanos Tsitsipas","Casper Ruud","Holger Rune","Hubert Hurkacz","Alex de Minaur","Taylor Fritz","Grigor Dimitrov","Tommy Paul","Ugo Humbert","Karen Khachanov","Ben Shelton","Felix Auger-Aliassime","Lorenzo Musetti","Sebastian Korda","Nicolas Jarry","Adrian Mannarino","Frances Tiafoe","Jan-Lennard Struff","Alexander Bublik","Tallon Griekspoor","Jiri Lehecka","Christopher Eubanks","Mackenzie McDonald","Andy Murray","Stan Wawrinka","Gael Monfils","Marin Cilic","Matteo Berrettini","Denis Shapovalov","Dominic Thiem","Borna Coric","Roberto Bautista Agut","Pablo Carreno Busta","Cameron Norrie","Daniel Evans","Laslo Djere","Yoshihito Nishioka","Miomir Kecmanovic","Alexei Popyrin","Jaume Munar","Marton Fucsovics","Richard Gasquet","Roberto Carballes Baena","Albert Ramos-Vinolas","Federico Coria","Pedro Cachin","Juan Pablo Varillas","Daniel Altmaier","Gregoire Barrere","Quentin Halys","Corentin Moutet","Luca Van Assche","Arthur Fils","Thiago Seyboth Wild","Alejandro Tabilo","Tomas Martin Etcheverry","Francisco Cerundolo","Sebastian Baez","Mariano Navone","Nuno Borges","Lorenzo Sonego","Matteo Arnaldi","Flavio Cobolli","Luciano Darderi","Zhizhen Zhang","Yunchaokete Bu","Juncheng Shang","James Duckworth","Max Purcell","Jordan Thompson","Aleksandar Vukic","Thanasi Kokkinakis","Adam Walton","Marcos Giron","Brandon Nakashima","Reilly Opelka","Tennys Sandgren","Denis Kudla","Jeffrey John Wolf","Michael Mmoh","Patrick Kypson","Zachary Svajda","Aleksandar Kovacevic","Emilio Nava","Nishesh Basavareddy","Ethan Quinn","Tristan Schoolkate","Coleman Wong","Hsu Yu-hsiou","Chak Lam Coleman Wong","Jacob Fearnley","Paul Jubb","Jan Choinski","Billy Harris","Liam Broady"];
const TENNIS_WTA = ["Iga Swiatek","Aryna Sabalenka","Coco Gauff","Elena Rybakina","Jessica Pegula","Ons Jabeur","Marketa Vondrousova","Maria Sakkari","Karolina Muchova","Jelena Ostapenko","Barbora Krejcikova","Beatriz Haddad Maia","Belinda Bencic","Caroline Garcia","Madison Keys","Liudmila Samsonova","Daria Kasatkina","Petra Kvitova","Victoria Azarenka","Veronika Kudermetova","Elina Svitolina","Anastasia Potapova","Mirra Andreeva","Linda Noskova","Ekaterina Alexandrova","Tatjana Maria","Danielle Collins","Sloane Stephens","Sofia Kenin","Marta Kostyuk","Dayana Yastremska","Lesia Tsurenko","Camila Giorgi","Martina Trevisan","Elisabetta Cocciaretto","Jasmine Paolini","Lucia Bronzetti","Sara Errani","Emma Raducanu","Katie Boulter","Harriet Dart","Jodie Burrage","Heather Watson","Lily Miyazaki","Naomi Osaka","Angelique Kerber","Donna Vekic","Petra Martic","Tara Wurth","Kaja Juvan","Tamara Zidansek","Xiyu Wang","Xinyu Wang","Lin Zhu","Siyu Wang","Yue Yuan","Shuai Zhang","Qinwen Zheng","Hong Yi Cody Wong","Ankita Raina","Rutuja Bhosale","Karman Kaur Thandi","Vaidya Bhardwaj","Yuki Naito","Mai Hontama","Nao Hibino","Sara Saito","Ayano Shimizu","Yuriko Miyazaki","Eudice Chong","Cody Wong","Haruka Kaji","En Shuo Liang","Peangtarn Plipuech","Sabina Sharipova","Alina Korneeva","Alexandra Eala","Darja Semenistaja","Ekaterina Yashina","Varvara Gracheva","Diana Shnaider","Kamilla Rakhimova","Marina Stakusic","Rebecca Marino","Leylah Fernandez","Bianca Andreescu","Eugenie Bouchard","Rebecca Sramkova","Anna Schmiedlova","Karolina Pliskova","Katerina Siniakova","Linda Fruhvirtova","Brenda Fruhvirtova","Sara Bejlek","Nika Radisic","Antonia Ruzic","Tena Lukas","Lucija Ciric Bagaric"];

const BASEBALL_NAMES = ["Shohei Ohtani","Aaron Judge","Juan Soto","Mookie Betts","Ronald Acuna Jr","Mike Trout","Fernando Tatis Jr","Bryce Harper","Matt Olson","Freddie Freeman","Yordan Alvarez","Corey Seager","Jose Ramirez","Rafael Devers","Trea Turner","Vladimir Guerrero Jr","Bo Bichette","Julio Rodriguez","Adley Rutschman","Corbin Carroll","Manny Machado","Nolan Arenado","Paul Goldschmidt","Nolan Jones","Spencer Strider","Gerrit Cole","Jacob deGrom","Zack Wheeler","Justin Verlander","Max Scherzer","Clayton Kershaw","Aaron Nola","Corbin Burnes","Shane McClanahan","Kevin Gausman","Framber Valdez","Sandy Alcantara","Luis Castillo","Carlos Rodon","Logan Webb","Joe Musgrove","Zac Gallen","Merrill Kelly","Hunter Greene","Nick Lodolo","Reid Detmers","Bobby Miller","Gavin Stone","Emmet Sheehan","Michael Grove","Ryan Pepiot","Gavin Lux","Miguel Rojas","Chris Taylor","Max Muncy","Will Smith","James Outman","Jason Heyward","David Peralta","Austin Barnes","Noah Syndergaard","Walker Buehler","Clayton Kershaw","Tony Gonsolin","Dustin May","Blake Treinen","Alex Vesia","Evan Phillips","Caleb Ferguson","Brusdar Graterol","Victor Gonzalez","Justin Bruihl","Michael Grove","Ryan Brasier","Joe Kelly","Chris Martin","Kenley Jansen","Daniel Hudson","Jake Marisnick","Austin Wynns","Patrick Mazeika","Yency Almonte","Gus Varland","Mike Busch","Taylor Ward","Luis Rengifo","Zach Neto","Brandon Drury","Eduardo Escobar","David Fletcher","Logan O'Hoppe","Matt Thaiss","Jo Adell","Mickey Moniak","Randal Grichuk","Hunter Renfroe","Taylor Ward","Mike Trout","Shohei Ohtani"];
const BASEBALL_TEAMS = ["Los Angeles Dodgers","New York Yankees","Atlanta Braves","San Diego Padres","Philadelphia Phillies","Houston Astros","Los Angeles Angels","New York Mets","Texas Rangers","Tampa Bay Rays","Toronto Blue Jays","Baltimore Orioles","Seattle Mariners","Minnesota Twins","Milwaukee Brewers","Chicago Cubs","St. Louis Cardinals","San Francisco Giants","Arizona Diamondbacks","Miami Marlins","Boston Red Sox","Cincinnati Reds","Cleveland Guardians","Detroit Tigers","Kansas City Royals","Chicago White Sox","Oakland Athletics","Pittsburgh Pirates","Colorado Rockies","Washington Nationals"];

const HOCKEY_NAMES_M = ["Tom Boon","Alexander Hendrickx","Arthur van Doren","Glenn Turner","Blake Govers","Blake Thomson","Johnny Belmonte","Mats Grambusch","Christopher Ruhr","Mark van Rijswijk","Robbert Kemperman","Sander de Wijn","Bjorn Kellerman","Billy Bakker","Valentin Verga","Victor Wegnez","Felix Denayer","Cedric Charlier","Arthur Verdussen","Nicolas de Kerpel","Tanguy Cosyns","Simon Gougnard","Gauthier Boccard","Loic van Doren","Maxime Plennevaux","Tommy Willems","Floris Wortelboer","Jip Janssen","Tijs van der Horst","Joep de Mol","Boris Burkhardt","Lukas Windfeder","Niklas Wellen","Benedikt Furk","Dieter Linnekogel","Mats Grambusch","Malte Hellwig","Justus Weigand","Marc Koll","Constantin Staib","Timothee Clement","Nicolas Dumont","Fabrice van Bockstal","Jerome Truyens","Romain Marq","Dylan Englebert","William Ghislain","Gilles Thomas","Antoine Kina","Tommy Willems","Sander Baart","Jelle Galema","Florian Fuchs","Moritz Furste","Tobias Hauke","Martin Zwicker","Oliver Korn","Jan-Philipp Rabente","Linus Butt","Marco Miltkau","Chris Wesley","Ashley Jackson","Barry Middleton","Henry Weir","Ian Sloan","Alan Forsyth","Chris Grassi","George Pinner","Harry Martin","David Condon","Ollie Willars","Liam Ansell","James Gall","Will Calnan","Jake Ferns","Zachary Lee","Jonah Klein","Nick Czepielewski","Pat Harris","Sean Flynn","Tom Crowder","Sam Olyslager","Kasey Lopresti","Tommy Doman","Asher Brown","Christian DeAngelis","Ethan Woods","Evan Burton","Tyler Bird","Matthew Gossett","Brian Palmer","Sam Mann","Jacob Jarvis","Aki Kaeppeler","Timur Shirokov","Rafat Hager","Pawel Bratkowski","Janusz Gorny","Mateusz Hulboj","Mateusz Kuznia","Jacek Lukaszewski","Piotr Sankowski","Matej Rojewski"];
const HOCKEY_NAMES_W = ["Eva de Goede","Xan de Waard","Lidewij Welten","Caia van Maasakker","Frédérique Matla","Maria Verschoor","Felice Albers","Stella van Gils","Josine Koning","Anne Veenendaal","Sanne Koolen","Ireen van den Assem","Anabel de la Fuente","Belén Iglesias","Lucía Jiménez","Marina Martín","Berta Bonastre","Silvia Muñoz","Marta Segú","Carlota Petchame","María López","Bea Pérez","Lola Riera","Alicia Magaz","Candela Mejías","Clara Ycart","Laura Barrios","Maialen García","Amelia del Carmen","Teresa Benítez","Alina Mailleux","Aline Stöckel","Lisa Altenburg","Katharina Kleinfeldt","Sara Strauss","Marlena Hüls","Nele Steffen","Valentina Schmitz","Lisa Schneider","Rebecca Abildgaard","Mathilde Abildgaard","Margrethe Seerup","Emma Frandsen","Line Krogh","Sara Knudsen","Kamilla Busk","Frida Nielsen","Maria Gade","Sofie Asping","Julie Holm","Hannah Martin","Laura Roper","Grace Balsdon","Lily Walker","Elizabeth Cann","Ellie Rayer","Isabelle Petter","Maddie Hinch","Elizabeth Neal","Elena Macleod","Francesca Burnett","Holly Court","Sonia French","Kirsty Mackay","Clare Hyland","Olivia Balle","Bronwyn Sheehan","Stephanie Dickins","Josie Milne","Jessica McQuade","Kaylee Andrew","Morgan Alexander","Lara Flinn","Margaret Byerly","Amanda Burhans","Katherine O'Donnell","Christina Linton","Olivia Horner","Samantha Berger","Megan Anderson","Heather Schaudt","Camille Koch","Elena Lauer","Laurel Appleton","Chantelle Severn","Megan Ellis","Tessa Kooij","Luna Fokke","Mickey de Koning","Maite Ladstatter","Pien Dicke","Mieke van der Vlugt","Linde van der Heijden","Eva van Agt","Laura Nunnink","Margot van Geffen"];
const HOCKEY_COUNTRIES = ["Australia","Belgium","Netherlands","Germany","India","United Kingdom","Spain","Argentina","New Zealand","South Africa","Ireland","France","Canada","Malaysia","Pakistan","China","Japan","South Korea","Egypt","Chile","United States","Austria","Poland","Italy","Scotland","Wales","Czech Republic","Ukraine","Russia","Ghana"];

const VOLLEYBALL_NAMES_M = ["Wilfredo Leon","Earvin N'Gapeth","Matey Kaziyski","Ivan Zaytsev","Micah Christenson","Matt Anderson","Taylor Sander","Aaron Russell","Thomas Jaeschke","Maxwell Holt","David Smith","Erik Shoji","Kawika Shoji","Yuji Nishida","Yuki Ishikawa","Ran Takahashi","Masahiro Sekita","Taishi Onodera","Nimir Abdel-Aziz","Thijs ter Horst","Maarten van Garderen","Wouter ter Maat","Just Dronkers","Gijs Jorna","Jorna de Boer","Luka Basic","Klemen Cebulj","Tine Urnaut","Jan Kozamernik","Alen Sket","Gabi Fernandez","Andres Villena","Miguel Ángel de Amo","Jorge Fernandez","Angel Trinidad","Jose Luis Linares","Fernando Fernandez","Augusto Colito","Liere de Lima","Henrique Honorato","Carlos Santos","Lucas Saatkamp","Wallace de Souza","Bruno Rezende","Yoandy Leal","Mauricio Souza","Douglas Souza","Lucas Lóh","Alain de Azevedo","William Peixoto","Fabio Paes","Thiery Santos","Matheus Santos","Luis Silva","Joao Silva","Pedro Mendes","Lucas Pereira","Gabriel Machado","Vinicius Rodrigues","Marcelo Costa","Juan Moreno","Samuel Carrillo","Franklin Diaz","Luis Sanchez","Maykel Linares","Rollandsson Leyva","Angel Aguilera","David Soler","Jesus Herrera","Brayan Rodriguez","Jose Aponza","Mario Rivera","Cristian Duarte","Daniel Pereira","Miguel Lopez","Pablo Baez","Rodrigo Villalba","Carlos Acosta","Luis Barreto","Juan Hernandez","Diego Gonzalez","Felipe Carmona","Carlos Carcamo","Joaquin Lagos","Vicente Parraguirre","Sebastian Castillo","Tomas Gago","Matias Banda","Reyner Velez","Gabriel Rivera","Ismael Sandoval","Jerry Torres","Jose Alvarado","Kevin Ramirez","Carlos Ventura","Luis Galeano","Emmanuel Martinez","David Acosta","Jorge Mendoza","Pedro Rodriguez"];
const VOLLEYBALL_NAMES_W = ["Zhu Ting","Paola Egonu","Eda Erdem","Melissa Vargas","Monica De Gennaro","Kimberly Hill","Michelle Bartsch-Hackley","Jordan Larson","Andrea Drews","Annie Drews","Foluke Akinradewo","Rachael Adams","Kelsey Robinson","Justine Wong-Orantes","Haleigh Washington","Chiaka Ogbogu","Kathryn Plummer","Jordan Thompson","Danielle Cuttino","Tiffany Clark","Tijana Boskovic","Brankica Mihajlovic","Maja Ognjenovic","Silvija Popovic","Bianka Busa","Katarina Lazovic","Jelena Blagojevic","Sara Lozo","Jovana Stevanovic","Minja Osmajic","Wang Mengjie","Zhang Changning","Yan Ni","Li Yingying","Gong Xiangyu","Yuan Xinyue","Ding Xia","Wang Yuanyuan","Liu Yanhan","Yang Hanyu","Kosheleva","Nataliya Goncharova","Irina Voronkova","Anna Lazareva","Kseniia Parubets","Viktoriia Gorbunova","Ekaterina Evdokimova","Polina Shemanova","Mariia Vorobyeva","Evgeniia Timoshkina","Elena Pietrini","Miriam Sylla","Caterina Bosetti","Lucia Bosetti","Anna Danesi","Alessia Orro","Ofelia Malinov","Indre Sorokaite","Elena Perinelli","Sara Alberti","Isabel Haak","Isabelle Haak","Julia Nilsson","Hanna Hellvig","Sofia Anderson","Elena Andersson","Linda Andersson","Julia Andersson","Elin Larsson","Emma Larsson","Maja Svalberg","Sarah Van Aalen","Marlies Janssens","Silke van Avermaet","Britt Herbots","Lise de Valk","Tine Klinkenberg","Charlotte Leys","Dominika Strumilo","Valerie Vossen","Jolien Wittock","Manon de Langhe","Lauren Page","Avery Skinner","Madi Bugg","Danielle Mahaffey","Shelly Stafford","Reagan Cooper","Claire Hoffman","Ella Fraser","Sarah Schmid","Maya McLeod","Emma McCloskey","Kate Massey","Lydia Vogler","Megan Harrison"];
const VOLLEYBALL_POSITIONS = ["OH","OP","MB","S","L","OH","OP","MB","S","L","OH","OP","MB","S","L","OH","OP","MB","S","L","OH","OP","MB","S","L","OH","OP","MB","S","L"];
const VOLLEYBALL_COUNTRIES = ["Poland","France","Brazil","Italy","USA","Japan","Russia","Iran","Argentina","Germany","Netherlands","Slovenia","Cuba","Canada","Bulgaria","Serbia","Turkey","China","Egypt","Korea","Australia","Tunisia","Ukraine","Czech Republic","Belgium","Portugal","Mexico","Qatar","Chile","Cameroon"];

const KABADDI_NAMES = ["Pardeep Narwal","Naveen Kumar","Maninder Singh","Rishank Devadiga","Deepak Niwas Hooda","Pawan Sehrawat","Sachin Tanwar","Ajay Thakur","Rahul Chaudhari","Siddharth Desai","Mohammadreza Shadlou","Abhishek Singh","Vikash Khandola","Nitin Rawal","Arjun Deshwal","Neeraj Kumar","Chandran Ranjit","Sagar","Vijay","Anup Kumar","Deepak Hooda","Rohit","Surjeet","Gaurav","Nitin","Sandeep","Amit","Sagar","Vishal","Sachin","Ashish","Pankaj","Naveen","Pardeep","Vivek","Rajesh","Mahinder","Vikrant","Somnath","Siddharth","Sunil","Mukesh","Karan","Ravi","Rohan","Aditya","Manjeet","Balwinder","Harjeet","Gagandeep","Aman","Krishan","Hardeep","Jai","Sagar","Kumar","Ravi","Shubham","Vikas","Parveen","Amarjeet","Gurvinder","Simranjit","Lovepreet","Sukhvinder","Amandeep","Jasveer","Ravinder","Sachin","Vikas","Mohit","Sunil","Hitesh","Rajesh","Dharma","Dharmendra","Ravi","Jagdish","Raman","Harsh","Sumit","Amit","Kuldeep","Anil","Vijay","Ravi","Deepak","Naveen","Sachin","Sahil","Vinay","Siddharth","Abhishek","Rahul","Amit","Pankaj","Vishal","Rohit","Vivek","Sunil","Rajesh","Amit"];
const KABADDI_TEAMS = ["Patna Pirates","Dabang Delhi KC","Bengal Warriors","UP Yoddhas","Puneri Paltan","Jaipur Pink Panthers","Bengaluru Bulls","Tamil Thalaivas","Gujarat Giants","Haryana Steelers","Telugu Titans","U Mumba","Jaipur Pink Panthers","Patna Pirates","Dabang Delhi KC","Bengaluru Bulls","UP Yoddhas","Tamil Thalaivas","Puneri Paltan","Gujarat Giants","Haryana Steelers","U Mumba","Telugu Titans","Bengal Warriors","Patna Pirates","Dabang Delhi KC","Jaipur Pink Panthers","Bengaluru Bulls","UP Yoddhas","Tamil Thalaivas"];

const ESPORTS_NAMES_VAL = ["TenZ","Demon1","jawgemo","Aspas","Chronicle","Something","Keznit","Sacy","FNS","Boaster","Derke","Alfajer","Leo","Jinggg","f0rsakeN","Monyet","Redgar","d3ffo","Sayf","Zekken","Marved","Victor","Crashies","yay","Meteor","Rb","Boo","AvovA","Florescent","Cender"];
const ESPORTS_NAMES_LOL = ["Faker","Chovy","Caps","369","Bin","Keria","Tian","Scout","Elk","Mata","Bang","Wolf","Ruler","Deft","Ming","JackeyLove","TheShy","Rookie","ShowMaker","Canyon","BeryL","Knight","Jiejie","Viper","Meiko","Tarzan","Ale","Light","Hang","Kanavi"];
const ESPORTS_NAMES_CS = ["ZywOo","s1mple","NiKo","m0NESY","ropz","device","twistzz","EliGE","NAF","frozen","Ax1Le","electroNic","sdy","jL","iM","Snappi","FalcoN","KSCERATO","yuurih","chelo","Jame","FL1T","zorte","mir","m0NESY","degster","headtr1ck","s1ren","t0rick","alpha"];
const ESPORTS_NAMES_DOTA = ["Nisha","Topias","Team Ame","Collapse","Mira","TORONTOTOKYO","Miposhka","Yatoro","Miracle-","SumaiL","Arteezy","RAMZES666","NoOne","Nightfall","Dry","Khalid","MinD_ContRoL","GH","KuroKy","Matumbaman","zai","Puppey","Ace","33","Malik","Crystallis","BZM","ATF","Skiter","Seleri"];
const ESPORTS_TEAMS = ["Sentinels","Cloud9","DRX","Fnatic","LOUD","Evil Geniuses","Paper Rex","Oxygen Esports","KRÜ Esports","Navi","FaZe Clan","Team SoloMid","Team Liquid","G2 Esports","100 Thieves","NRG Esports","MIBR","FURIA Esports","Leviatán","Karmine Corp","T1","Gen.G","Dplus KIA","DRX","KT Rolster","Hanwha Life Esports","DK","Bilibili Gaming","Top Esports","JDG"];

const TABLETENNIS_NAMES_M = ["Fan Zhendong","Wang Chuqin","Ma Long","Liang Jingkun","Lin Gaoyuan","Lin Shidong","Xu Xin","Zhou Qihao","Tomokazu Harimoto","Zhang Benzhihe","Dang Qiu","Truls Moregardh","Hugo Calderano","Darko Jorgic","Lin Yun-ju","Kao Cheng-Jui","Chuang Chih-Yuan","Patrick Franziska","Dimitrij Ovtcharov","Timo Boll","Quadri Aruna","Omar Assar","Marcos Freitas","Simon Gauzy","Lebrun Alexis","Lebrun Felix","Kanak Jha","Jang Woo-jin","Lim Jong-hoon","An Jae-hyun","Cho Seung-min","Alvaro Robles","Daniel Habesohn","Benedikt Duda","Anton Kallberg","Kristian Karlsson","Jon Persson","Mattias Falck","Emil Johansson","Nicolas Burgos","Gaston Alto","Horacio Cifuentes","Santiago Lorenzo","Diego Cachi","Andy Pereira","Brian Afanador","Alberto Mino","Rodrigo Gil","Cedric Nuytinck","Robin Devos","Adrien Rassenfosse","Florent Lambiet","Martin Allegre","Liam Pitchford","Paul Drinkhall","Sam Walker","Tom Jarvis","David McBeath","Joshua Weatherby","Shayan Siraj","Filip Zeljko","Toma Kolarek","Andrei Istrate","Iulian Chirita","Eduard Ionescu","Victor Vlad","Ovidiu Merutiu","Cristian Pletea","Hunor Szocs","Bence Majoros","Tamas Lakatos","Adam Szudi","Nandor Ecseki","Daniel Koszoru","Marton Marsi","Csaba Andras","Alexander Chen","Amin Ahmadian","Nima Alamian","Noshad Alamian","Seyed Amiri","Soroush Pournazari","Amir Hossein","Pedar Arvand","Mobin Sedighi","Navid Shams","Ashkan Ahmadzadeh","Mohammad Amin","Vahid Mohammadi","Sajad Mohammadi","Arman Hajipour","Ali Khoshkholeh","Seyed Reza","Mohsen Mohammadi","Erfan Ghasemi","Nima Sadeghi","Soroush Mohammadi"];
const TABLETENNIS_NAMES_W = ["Sun Yingsha","Wang Manyu","Wang Yidi","Chen Meng","Chen Xingtong","Shen Yubin","Qian Tianyi","Fan Siqi","Zhang Rui","Mima Ito","Hina Hayata","Miu Hirano","Miyuu Kihara","Miyu Nagasaki","Miwa Harimoto","Sakura Mori","Yuka Umemoto","Satsuki Odo","Nina Mittelham","Han Ying","Shan Xiaona","Sabine Winter","Annett Kaufmann","Doo Hoi Kem","Lee Ho Ching","Zhu Cheng Zhu","Minnie Soo","Ng Wing Nam","Zhang Mo","Bernadette Szocs","Elizabeta Samara","Andreea Dragoman","Adina Diaconu","Tania Plaian","Maria Yovkova","Polina Mikhailova","Sofia Polcanova","Min Yang","Liu Jia","Matilda Ekholm","Cezaryna Stankowska","Natalia Bajor","Klaudia Kusiak","Lily Zhang","Rachel Sung","Amy Wang","Kristen Li","Sarah Jalli","Yue Wu","Sally Moy","Samantha Yang","Nina Chen","Tiffany Ke","Ying Sun","Berta Chen","Eva Lee","Hong Wang","Lin Chen","Xiaohua Hu","Yan Huang","Li Fan","JianJian Zhang","Katherine Li","Megan Chen","Joyce Yang","Xin Chen","Sophia Zhang","Alice Li","Grace Wang","Lily Wen","Helen Wu","Michelle Zhao","Jing Chen","Yan Li","Xiaoping Wang","Xiaohui Zhang","Yan He","Ting Liu","Fang Chen","Hong Li","Xiao Chen","Jie Zhang","Ming Li","Wei Wang","Fen Yang","Li He","Xia Zhang","Yan Wang","Jing Li","Lin He","Hong Zhang","Fang Liu","Yan Chen","Xiao Li","Jie Wang","Feng Yang","Wei Chen","Ming Zhang","Li Wang"];

const TENNIS_COUNTRIES = ["Spain","Italy","Serbia","Russia","Greece","Norway","Denmark","Poland","Australia","USA","Bulgaria","Germany","Canada","France","UK","Argentina","Chile","Croatia","Switzerland","Netherlands","Belgium","Japan","China","Czech Republic","Romania","Ukraine","Tunisia","Kazakhstan","Brazil","Hungary"];
const TTE_CTRY_M = ["China","Japan","Germany","Brazil","Chinese Taipei","France","Sweden","South Korea","India","Nigeria","Egypt","Portugal","Slovenia","Denmark","Austria","Spain","Argentina","Croatia","Puerto Rico","Poland","Romania","Hungary","Belgium","England","Iran","Kazakhstan","Luxembourg","Singapore","Hong Kong","Australia"];
const TTE_CTRY_W = ["China","Japan","Germany","Hong Kong","South Korea","Romania","Austria","Chinese Taipei","Singapore","Thailand","Poland","USA","Portugal","France","Egypt","India","Brazil","Australia","England","Hungary","Sweden","Italy","Spain","Puerto Rico","Turkey","Netherlands","Luxembourg","Czech Republic","Kazakhstan","Argentina"];

// ─── GENERATOR FUNCTIONS (same as server.js) ─────────────────────────────────

function makePlayers(raw) {
  return raw.map((p, i) => ({
    rank: i + 1, name: p[0], country: p[1], rating: p[2],
    matches: p[3], runs: p[4], wkts: p[5], avg: p[6], econ: p[7]
  }));
}

function generateCricketData(format, role, gender) {
  const key = `${format}_${role}_${gender}`;
  const direct = CRICKET_RAW[key];
  if (direct && direct.length >= 100) return makePlayers(direct.slice(0, 100));
  const names = gender === "women" ? CRICKET_NAMES.slice(0,50) : CRICKET_NAMES;
  const countries = gender === "women" ? CRICKET_COUNTRIES_W : CRICKET_COUNTRIES;
  const count = 100;
  const players = [];
  const startRating = 700;
  for (let i = 0; i < count; i++) {
    const name = names[i % names.length];
    const country = countries[i % countries.length];
    const rating = Math.max(1, startRating - Math.floor(i * 6.5));
    const isBowl = role === "bowl";
    const isAR = role === "ar";
    const matches = Math.round(10 + Math.random() * 80);
    const runs = isBowl ? Math.round(50 + Math.random() * 500) : isAR ? Math.round(200 + Math.random() * 5000) : Math.round(500 + Math.random() * 10000);
    const wkts = isBowl ? Math.round(20 + Math.random() * 200) : isAR ? Math.round(10 + Math.random() * 100) : 0;
    const avg = runs > 0 ? (runs / Math.max(1, Math.round(matches * 0.8))).toFixed(1) : "0.0";
    const econ = (3.5 + Math.random() * 3).toFixed(1);
    players.push({ rank: i + 1, name, country, rating, matches, runs, wkts, avg: parseFloat(avg), econ: parseFloat(econ) });
  }
  if (role === "bowl") players.sort((a, b) => b.wkts - a.wkts);
  else if (role === "ar") players.sort((a, b) => (b.runs + b.wkts * 20) - (a.runs + a.wkts * 20));
  else players.sort((a, b) => b.runs - a.runs);
  players.forEach((p, i) => p.rank = i + 1);
  return players;
}

function generateFootball(cat) {
  const parts = cat.split("_");
  const stat = parts[0];
  const gender = parts[1] || "men";
  const prefix = gender === "women" ? "W. " : "";
  const count = 100;
  const players = [];
  for (let i = 0; i < count; i++) {
    const name = `${prefix}${FOOTBALL_NAMES[i % FOOTBALL_NAMES.length]}`;
    const team = FOOTBALL_TEAMS[i % FOOTBALL_TEAMS.length];
    const country = FOOTBALL_COUNTRIES[i % FOOTBALL_COUNTRIES.length];
    const position = FOOTBALL_POSITIONS[i % FOOTBALL_POSITIONS.length];
    const base = 100 - i;
    const matches = Math.round(20 + Math.random() * 30);
    const goals = stat === "scorers" ? Math.max(0, Math.round(base * 0.5 + Math.random() * 10)) : Math.round(5 + Math.random() * 15);
    const assists = stat === "assists" ? Math.max(0, Math.round(base * 0.35 + Math.random() * 8)) : Math.round(3 + Math.random() * 12);
    const rating = (6.5 + Math.random() * 2.5).toFixed(1);
    players.push({ rank: i + 1, name, country, team, position, goals, assists, matches, rating: parseFloat(rating) });
  }
  if (stat === "scorers") players.sort((a, b) => b.goals - a.goals);
  else if (stat === "assists") players.sort((a, b) => b.assists - a.assists);
  else players.sort((a, b) => parseFloat(b.rating) - parseFloat(a.rating));
  players.forEach((p, i) => p.rank = i + 1);
  return players;
}

function generateBasketball(cat) {
  const count = 100;
  const positions = ["PG","SG","SF","PF","C"];
  const teams = ["LAL","BOS","GSW","MIL","PHI","MIA","DEN","PHX","DAL","OKC","NYK","BKN","CLE","MIN","MEM","NOP","LAC","SAS","SAC","ATL","CHI","HOU","UTA","ORL","WAS","POR","CHA","DET","IND","TOR"];
  const names = ["LeBron James","Stephen Curry","Kevin Durant","Giannis Antetokounmpo","Luka Doncic","Joel Embiid","Nikola Jokic","Shai Gilgeous-Alexander","Anthony Davis","Jayson Tatum","Devin Booker","Damian Lillard","Trae Young","Anthony Edwards","Jimmy Butler","Ja Morant","Donovan Mitchell","Tyrese Haliburton","Jalen Brunson","Bam Adebayo","Kyrie Irving","Kawhi Leonard","Paul George","Rudy Gobert","Zion Williamson","LaMelo Ball","Chet Holmgren","Victor Wembanyama","Jaylen Brown","Mikal Bridges","De'Aaron Fox","Domantas Sabonis","Lauri Markkanen","Cade Cunningham","Scottie Barnes","Evan Mobley","Jaren Jackson Jr","Julius Randle","Brandon Ingram","Zach LaVine","DeMar DeRozan","Nikola Vucevic","Christian Wood","Jusuf Nurkic","Clint Capela","Jonas Valanciunas","Steven Adams","Brook Lopez","Myles Turner","Kristaps Porzingis","Karl-Anthony Towns","Alperen Sengun","Walker Kessler","Nic Claxton","Jarrett Allen","Ivica Zubac","Daniel Gafford","Jakob Poeltl","Wendell Carter Jr","Mark Williams","Derrick Lively II","Dereck Lively","Onyeka Okongwu","Jabari Smith Jr","Keegan Murray","Trey Murphy III","Herbert Jones","Austin Reaves","Jordan Clarkson","Malik Monk","Buddy Hield","Eric Gordon","Naji Marshall","Coby White","Immanuel Quickley","Jaden Ivey","Scoot Henderson","Keyonte George","Jalen Suggs","Cole Anthony","RJ Barrett","Quentin Grimes","Josh Hart","Donte DiVincenzo","Gary Trent Jr","Reggie Jackson","Monte Morris","Tyus Jones","Mike Conley","Chris Paul","Kyle Lowry","Marcus Smart","Dennis Schroder","Spencer Dinwiddie","Bogdan Bogdanovic","Luke Kennard","Klay Thompson","Malik Beasley","Norman Powell"];
  const players = [];
  for (let i = 0; i < count; i++) {
    const name = names[i % names.length];
    const team = teams[i % teams.length];
    const position = positions[i % positions.length];
    const base = 35 - i * 0.3;
    const points = Math.max(0, (base + Math.random() * 8)).toFixed(1);
    const rebounds = Math.max(0, (base * 0.4 + Math.random() * 4)).toFixed(1);
    const assists = Math.max(0, (base * 0.35 + Math.random() * 5)).toFixed(1);
    const fg_pct = (0.40 + Math.random() * 0.15).toFixed(3);
    const rating = (base * 1.5 + Math.random() * 5).toFixed(0);
    players.push({ rank: i + 1, name, team, position, points: parseFloat(points), rebounds: parseFloat(rebounds), assists: parseFloat(assists), fg_pct: parseFloat(fg_pct), rating: parseFloat(rating) });
  }
  if (cat === "rebounds") players.sort((a, b) => b.rebounds - a.rebounds);
  else if (cat === "assists") players.sort((a, b) => b.assists - a.assists);
  else players.sort((a, b) => b.points - a.points);
  players.forEach((p, i) => p.rank = i + 1);
  return players;
}

function generateTennis(cat) {
  const parts = cat.split("_");
  const type = parts[0];
  const tCat = parts[1] || "singles";
  const pool = type === "atp" ? TENNIS_ATP : TENNIS_WTA;
  const count = 100;
  const players = [];
  for (let i = 0; i < count; i++) {
    const name = pool[i % pool.length];
    const country = TENNIS_COUNTRIES[i % TENNIS_COUNTRIES.length];
    const points = Math.max(1, Math.round(10000 - i * 70 + Math.random() * 50));
    const tournaments = Math.round(10 + Math.random() * 20);
    const titles = Math.round(i < 10 ? 5 + Math.random() * 15 : Math.random() * 5);
    const winrate = (50 + Math.random() * 40).toFixed(1);
    const prize = (i < 30 ? (10 - i * 0.3) : Math.random() * 3).toFixed(1);
    players.push({ rank: i + 1, name, country, points, tournaments, titles, winrate: parseFloat(winrate), prize: parseFloat(prize) });
  }
  players.sort((a, b) => b.points - a.points);
  players.forEach((p, i) => p.rank = i + 1);
  return players;
}

function generateBaseball(cat) {
  const count = 100;
  const positions = ["1B","2B","3B","SS","OF","C","DH","P"];
  const players = [];
  for (let i = 0; i < count; i++) {
    const name = BASEBALL_NAMES[i % BASEBALL_NAMES.length];
    const team = BASEBALL_TEAMS[i % BASEBALL_TEAMS.length];
    const position = positions[i % positions.length];
    const base = 70 - i * 0.6;
    const hr = Math.max(0, Math.round(base * 0.5 + Math.random() * 10));
    const avg = Math.min(0.350, (0.220 + Math.random() * 0.12)).toFixed(3);
    const rbi = Math.max(0, Math.round(base * 1.5 + Math.random() * 20));
    const ops = (0.650 + Math.random() * 0.4).toFixed(3);
    const games = Math.round(100 + Math.random() * 60);
    players.push({ rank: i + 1, name, team, position, hr, avg: parseFloat(avg), rbi, ops: parseFloat(ops), games });
  }
  if (cat === "hr") players.sort((a, b) => b.hr - a.hr);
  else if (cat === "avg") players.sort((a, b) => b.avg - a.avg);
  else if (cat === "rbi") players.sort((a, b) => b.rbi - a.rbi);
  else players.sort((a, b) => b.ops - a.ops);
  players.forEach((p, i) => p.rank = i + 1);
  return players;
}

function generateHockey(cat) {
  const parts = cat.split("_");
  const stat = parts[0];
  const gender = parts[1] || "men";
  const pool = gender === "women" ? HOCKEY_NAMES_W : HOCKEY_NAMES_M;
  const count = 100;
  const positions = ["FW","MF","DF","GK"];
  const players = [];
  for (let i = 0; i < count; i++) {
    const name = pool[i % pool.length];
    const country = HOCKEY_COUNTRIES[i % HOCKEY_COUNTRIES.length];
    const position = positions[i % positions.length];
    const base = 80 - i * 0.5;
    const goals = Math.max(0, Math.round(base * 0.4 + Math.random() * 8));
    const assists = Math.max(0, Math.round(base * 0.3 + Math.random() * 6));
    const matches = Math.round(30 + Math.random() * 100);
    const rating = (60 + Math.random() * 35).toFixed(0);
    players.push({ rank: i + 1, name, country, position, goals, assists, matches, rating: parseFloat(rating) });
  }
  if (stat === "goals") players.sort((a, b) => b.goals - a.goals);
  else players.sort((a, b) => b.assists - a.assists);
  players.forEach((p, i) => p.rank = i + 1);
  return players;
}

function generateVolleyball(cat) {
  const parts = cat.split("_");
  const stat = parts[0];
  const gender = parts[1] || "men";
  const pool = gender === "women" ? VOLLEYBALL_NAMES_W : VOLLEYBALL_NAMES_M;
  const count = 100;
  const players = [];
  for (let i = 0; i < count; i++) {
    const name = pool[i % pool.length];
    const country = VOLLEYBALL_COUNTRIES[i % VOLLEYBALL_COUNTRIES.length];
    const position = VOLLEYBALL_POSITIONS[i % VOLLEYBALL_POSITIONS.length];
    const base = 90 - i * 0.5;
    const points = Math.max(0, Math.round(base * 1.2 + Math.random() * 20));
    const spikes = Math.max(0, Math.round(base * 0.5 + Math.random() * 10));
    const blocks = Math.max(0, Math.round(base * 0.2 + Math.random() * 5));
    const aces = Math.max(0, Math.round(base * 0.1 + Math.random() * 3));
    const rating = (70 + Math.random() * 28).toFixed(0);
    players.push({ rank: i + 1, name, country, position, points, spikes, blocks, aces, rating: parseFloat(rating) });
  }
  if (stat === "points") players.sort((a, b) => b.points - a.points);
  else if (stat === "spikes") players.sort((a, b) => b.spikes - a.spikes);
  else players.sort((a, b) => b.blocks - a.blocks);
  players.forEach((p, i) => p.rank = i + 1);
  return players;
}

function generateKabaddi(cat) {
  const count = 100;
  const positions = ["Raider","Defender","All-Round"];
  const players = [];
  for (let i = 0; i < count; i++) {
    const name = KABADDI_NAMES[i % KABADDI_NAMES.length];
    const team = KABADDI_TEAMS[i % KABADDI_TEAMS.length];
    const position = positions[i % positions.length];
    const base = 90 - i * 0.5;
    const raid = Math.max(0, Math.round(base * 2 + Math.random() * 30));
    const tackle = Math.max(0, Math.round(base * 1.2 + Math.random() * 20));
    const total = raid + tackle;
    const matches = Math.round(20 + Math.random() * 60);
    const rating = (60 + Math.random() * 35).toFixed(0);
    players.push({ rank: i + 1, name, team, position, raid_pts: raid, tackle_pts: tackle, total_pts: total, matches, rating: parseFloat(rating) });
  }
  if (cat === "raid") players.sort((a, b) => b.raid_pts - a.raid_pts);
  else if (cat === "tackle") players.sort((a, b) => b.tackle_pts - a.tackle_pts);
  else players.sort((a, b) => b.total_pts - a.total_pts);
  players.forEach((p, i) => p.rank = i + 1);
  return players;
}

function generateEsports(cat) {
  const count = 100;
  let pool;
  let defaultGame;
  switch (cat) {
    case "valorant": pool = ESPORTS_NAMES_VAL; defaultGame = "Valorant"; break;
    case "lol": pool = ESPORTS_NAMES_LOL; defaultGame = "League of Legends"; break;
    case "cs2": pool = ESPORTS_NAMES_CS; defaultGame = "CS:GO/CS2"; break;
    case "dota2": pool = ESPORTS_NAMES_DOTA; defaultGame = "Dota 2"; break;
    default: pool = [...ESPORTS_NAMES_VAL, ...ESPORTS_NAMES_LOL, ...ESPORTS_NAMES_CS, ...ESPORTS_NAMES_DOTA]; defaultGame = "Multi"; break;
  }
  const GAMES_LIST = ["Valorant","League of Legends","CS:GO/CS2","Dota 2","Fortnite","Overwatch"];
  const players = [];
  for (let i = 0; i < count; i++) {
    const name = pool[i % pool.length];
    const team = ESPORTS_TEAMS[i % ESPORTS_TEAMS.length];
    const g = cat === "all" ? GAMES_LIST[i % GAMES_LIST.length] : defaultGame;
    const earnings = (i < 20 ? (5 - i * 0.2) : Math.random() * 2).toFixed(2);
    const tournaments = Math.round(5 + Math.random() * 40);
    const winrate = (40 + Math.random() * 45).toFixed(1);
    const rating = (65 + Math.random() * 30).toFixed(0);
    players.push({ rank: i + 1, name, team, game: g, earnings: parseFloat(earnings), tournaments, winrate: parseFloat(winrate), rating: parseFloat(rating) });
  }
  players.sort((a, b) => b.earnings - a.earnings);
  players.forEach((p, i) => p.rank = i + 1);
  return players;
}

function generateTableTennis(cat) {
  const parts = cat.split("_");
  const tCat = parts[0];
  const gender = parts[1] || "men";
  const pool = gender === "women" ? TABLETENNIS_NAMES_W : TABLETENNIS_NAMES_M;
  const countries = gender === "women" ? TTE_CTRY_W : TTE_CTRY_M;
  const count = 100;
  const players = [];
  for (let i = 0; i < count; i++) {
    const name = pool[i % pool.length];
    const country = countries[i % countries.length];
    const base = 9000 - i * 65;
    const points = Math.max(1, Math.round(base + Math.random() * 100));
    const tournaments = Math.round(5 + Math.random() * 20);
    const titles = Math.round(i < 15 ? 3 + Math.random() * 10 : Math.random() * 4);
    const winrate = (50 + Math.random() * 40).toFixed(1);
    const prize = (i < 25 ? (5 - i * 0.15) : Math.random() * 2).toFixed(2);
    players.push({ rank: i + 1, name, country, points, tournaments, titles, winrate: parseFloat(winrate), prize: parseFloat(prize) });
  }
  if (tCat === "singles") players.sort((a, b) => b.points - a.points);
  else players.sort((a, b) => b.titles - a.titles);
  players.forEach((p, i) => p.rank = i + 1);
  return players;
}

// ─── GENERATE ALL DATA ───────────────────────────────────────────────────────

function generateAll() {
  const output = {};

  for (const [sportId, config] of Object.entries(SPORTS_CONFIG)) {
    const sportData = {};
    for (const cat of config.categoryKeys) {
      let players;
      switch (sportId) {
        case "cricket": {
          const parts = cat.split("_");
          players = generateCricketData(parts[0], parts[1], parts[2] || "men");
          break;
        }
        case "football": players = generateFootball(cat); break;
        case "basketball": players = generateBasketball(cat); break;
        case "tennis": players = generateTennis(cat); break;
        case "baseball": players = generateBaseball(cat); break;
        case "hockey": players = generateHockey(cat); break;
        case "volleyball": players = generateVolleyball(cat); break;
        case "kabbaddi": players = generateKabaddi(cat); break;
        case "e-sports": players = generateEsports(cat); break;
        case "table-tennis": players = generateTableTennis(cat); break;
      }
      sportData[cat] = players;
    }
    output[sportId] = sportData;
  }

  return output;
}

const data = generateAll();
const filePath = path.join(__dirname, "..", "data", "player-rankings.json");
fs.writeFileSync(filePath, JSON.stringify(data, null, 2));
console.log("Written " + filePath);
console.log("Total sports: " + Object.keys(data).length);
let totalPlayers = 0;
for (const [sport, cats] of Object.entries(data)) {
  for (const [cat, players] of Object.entries(cats)) {
    totalPlayers += players.length;
  }
}
console.log("Total player entries: " + totalPlayers);
