yacc -d -y -v 1705007.y
echo '1'
g++ -w -c -o y.o y.tab.c
echo '2'
flex 1705007.l		
echo '3'
g++ -w -c -o l.o lex.yy.c
echo '4'
g++ -o a.out y.o l.o -lfl
echo '5'
./a.out input.c log.txt error.txt code.asm
echo '6'
g++ -o optimizer optimizer.cpp
echo '7'
./optimizer
