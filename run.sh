cd Agregador && ghc --make Main.hs && cd ..
cd Processador && javac src/*.java -d bin && cd ..
java -cp Processador/bin Main metrics.txt dataset.csv Agregador/Main
