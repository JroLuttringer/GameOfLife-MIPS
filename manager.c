#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>
#include <errno.h>
#include <time.h>
#include <sys/wait.h>

/*
 * FONCTION: creationProc
 * retour : pid_t 
 * arguments : -
 * 
 * création d'un processus fils
 * */

pid_t creationProc(){

        pid_t pid;
		
		do{
		pid = fork();
		}while ((pid == -1) &&(errno=EAGAIN)); // Vu que EAGAIN se déclenche si l'utilisateur a trop de 	
		return pid;							 // proccess en cours d'exe. , on peut se permettre de réitirer
}											// la demande de création.




/*
 * FONCTION : pausemips
 * retour : -
 * arguments : int pflag : sert à déterminer quelle type de fonction doit etre utiliser 
 * 							(dépend de l'unité de temps choisie)
 * 			   int tempspause : temps que doit durer la pause
 * 
 * Fait une pause d'un temps donné
 * */
void pausemips(int pflag,int tempspause){
	struct timespec x;
	x.tv_sec = tempspause / 1000000000;
	x.tv_nsec = tempspause % 1000000000L;
	if(pflag == 1)sleep(tempspause);
	if(pflag == 2)usleep(tempspause*1000);
	if(pflag == 3)nanosleep(&x,NULL);
}

/*FONCTION : parsing
 * retour : -
 * arguments : argc (nombre d'arguments)
 * 			   argv tableaux d'arguments
 * 			   tp : pointeur permettant de changer la variagle du temps de la pause
 * 			   ut : pointeur permettant de changer l'unité de temps
 * 			  file : nom du fichier
 */
char* parsing(int argc, char** argv, int* tp ,int* ut,char* file){
	int opt;
	int tmp;
	while(( opt = getopt(argc,argv,"t:u:f:")) != -1){
		switch (opt){
			case 't':	//temps de pause
				*tp=atoi(optarg);
			break;
				
			case 'u': //unité
				tmp=optarg[0];
				if (tmp=='s')*ut=1;
				if (tmp=='m')*ut=2;
				if (tmp=='n')*ut=3;
			break;
			
			case 'f': //file
				file=optarg;
				
			break;
			
			default:
				printf("Usage : make run args=-f <fichier> [-t] temps de pause [-u] unité de temps");
				exit(EXIT_FAILURE);
			break;
		}
	}
	
	return file;
	
}


/* fonctionnement global du main :
 * Le programme va créer un processus, du quel se lancera le programme assembleur via spim
 * Le programme communique le nom du fichier.txt correspodant à la génération 0
 * Le programme MIPS va créer une génération, l'envoyer sur sa sortie standard et envoyer
 * un signe au manager lui indiquant qu'une génération à été crée
 * En recevant ce signal, le manager va activer une pause de X secondes, puis envoyer un signal
 * au programme MIPS lui indiquant de créer la génération suivante
 * Le programme s'arrête si la grille se stabilise. Le mips se charge de vérifier si une grille est stable
 * */

int main(int argc,char* argv[]){
	
	/*création pipes*/
	int pfdin[2]; // création du pipe in
	int pfdout[2];//création du pipe out
	pipe(pfdin);
	pipe(pfdout);
	
	
	int i=0;
	int nbgen=0;
	int pause = 1;//temps de pause par défaut
	int *Ppause = &pause;
	char* file = "jeudelavie.txt"; //file par défaut
	int unit =1;
	int * Punit=&unit;//unité de temps par défaut
	file=parsing(argc,argv,Ppause,Punit,file);	
	pid_t pid = creationProc(); //duplication proc et renvoie du PID fils
	
	switch(pid){
		case -1:
			printf("Echec lors de la création du processus\n");
			return EXIT_FAILURE;
		break;		
		
		case 0:			//si processus fils
			
			close(pfdin[1]);
			dup2(pfdin[0],STDIN_FILENO); 
			
			char buffer[256]; //nom du fichier
			fgets(buffer,sizeof(buffer),stdin); 
			char *arg[5] = {"spim","-f","projet_archi.asm",buffer,NULL}; 			
			close(pfdout[0]);
			dup2(pfdout[1],STDOUT_FILENO);						
			execv("/usr/bin/spim",arg); //on lance l'asm		
				
		break;		
		
		default:
			close(pfdin[0]); //fermeture sortie du pere
			write(pfdin[1],file,256);//recup du nom du fichier
		
			char buffer2[1];
			close(pfdout[1]);
			printf("Generation %d\n",nbgen);
			nbgen++;
			while(read(pfdout[0],buffer2,1)){
				if(i>177){ //pour ne pas afficher l'interface spim
								
					if(buffer2[0]==6){
						pausemips(unit,pause);
						write(pfdin[1],"A",1);
						printf("Generation %d\n",nbgen);
						nbgen++;
					
					}
					else{
						printf("%c",buffer2[0]);	
					}
		
				}
				
				i++;
			}
			
		break;
	}
				
	printf("la grille est stable !\n");
	return EXIT_SUCCESS;
}
