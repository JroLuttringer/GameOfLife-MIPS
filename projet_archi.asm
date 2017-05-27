#---------------------------------------------------------#
#		PROJET ARCHITECTURE DES
#		ORDINATEURS
#
#JEAN-ROMAIN
#LUTTRINGER
#
#Lancé à l'aide du manager, ce programme calcule les
#générations suivant d'une grille
#
#Le programme recoit un nom de fichier en entrée,
#recupère les informations de la premiere ligne pour pouvoir
#allouer un espace permettant de recupérer le fichier en entier
#
#Il recupère ensuite la matrice du fichier et effectue les calculs dessus
#
#Variables Globales utilisée :
#	$s0 : caractère des cellules mortes
#	$s1 : caractère des cellules vivantes
#	$s2 : tableau contenant la génération suivante
#	$s3 : file descriptor
#	$s4 : taille totale du tableau
#	$s5 : génération actuelle
#	$s6 : largeur
# 	$s7 : hauteur
#----------------------------------------------------------#
.data
	buffer: .byte 15
.text

main:	
	lw $a0,4($a1) 		#recupere le nom du fichier 
	move $t2,$a0		#sauvegarde temporaire du nom
	jal openfile
	move $s3,$v0
	move $a0,$v0
	jal readfirstligne
	jal extractinfo
	move $a1,$s6
	move $a0,$s7
	mul $a0,$a0,$a1
	jal allouertab
	move $s2,$v1
	move $s5,$v0
	move $a0,$s3		#chargement du FD à fermer
	jal closefile		#fermeture du fichier
	move $a0,$t2	
	jal openfile
	add $a0,$s4,$s6
	add $a0,15
	jal recupfich
	move $a0,$v0
	jal loadtab
while:	
	move $a0,$s5		#affiche la génération actuelle	
	jal printarray
attente:
	li $a0,6
	li $v0,11
	syscall
	li $v0, 12
	syscall
	bne $v0, 65,attente
	move $a0,$s5	
	jal jeudelavie			#lance le jeu de la vie
	move $t1,$s5
	move $s5,$s2			#échange tableau
	move $s2,$t1
	move $a0,$s2
	move $a1,$s5
	jal check_chg
	beq $v0,1,finprog
	j while
finprog:
	jal exit




#----------------------------------------------#
#func : openfile
#args : $a0 nom du fichier
#return : $v0 file descriptor
#regs used : $v0,$a2,$a1
#
#ouvre un fichier en mode "read only"
#----------------------------------------------#
openfile:
	li $v0,13 #syscall: ouverture d'un fichier
	li $a1,0  #flag : read 
	li $a2,0  #mode :ignoré
	syscall
	jr $ra	  #retour à l'appelant 






#---------------------------------------------------#
#func : readfirstligne:				    
#args : $a0 nom du fichier
#			    
#lit les 15 premiers bytes du fichier et les 
#met dans le buffer
#---------------------------------------------------#
readfirstligne:
	li $v0,14
	la $a1,buffer
	li $a2,15
	syscall
	jr $ra





#-------------------------------------------------#
#func: extractinfo
#retour :-
#regs mod : $v0,$t[0-1],$a[0-1]
#
#Sauvegarde dans les registre $s0,$s1,$s7,$s6
#les caractère représentant les cellules vivantes
#et morte, la largeur et la hauteur du tableau
#-------------------------------------------------#

extractinfo:
	la $t0,buffer 
	li $v0,0   #on met $v0 à 0
	li $a1,0
		
	atoi:				#boucle pour convertir
		lb $t1,($t0)		#l'ascii en entier
		subu $t1,$t1,48
		mul $v0,$v0,10
		add $v0,$v0,$t1
		add $t0,$t0,1
		lb $t1,($t0)
		bne $t1,32,atoi
		bne $a1,0,cell
		move $a1,$v0
		li $v0,0	
		add $t0,$t0,1
		j atoi

cell:
	move $s6,$v0
	add $t0,$t0,1
	lb $s0,($t0)
	add $t0,$t0,2
	lb $s1,($t0)
	move $s7,$a1	
	mul $s4,$s6,$s7
	jr $ra

#----------------------------------------#
#func : allouertab
#arg : $a0,largeur / $a1, hauteur
#return : $v0,$v1 array adress
#reg mod : $v0,$v1
#
#alloue deux tableaux de meme taille :
#un contiendra la génération actuelle,
#l'autre la génération suivante
#----------------------------------------#

allouertab:
	li $v0,9	
	syscall
	move $v1,$v0	
	li $v0,9
	syscall	
	jr $ra

#---------------------------------------#
#func : recupfich
#arg : $a0 taille à réserver
#retour : $v0 , tableau alloué/chargé
#reg mods : $v0,$a[0-2],$t1
#---------------------------------------#

recupfich:
			#on alloue un espace égale à
	li $v0,9		#la taille du tableau + le buffer
	syscall			#afin de récupérer le fichier entier
	move $t1,$v0
	li $v0,14
	move $a1,$t1
	move $a2,$a0
	move $a0,$s3
	syscall	
	move $v0,$t1
	jr $ra
	
	
#-----------------------------------------#
#func: loadtab
#arg: $a0 : adresse du tableau source
#retour : -
#reg used : $t0,$t2,$t3
#----------------------------------------#

loadtab:
	li $t3,0
	move $t2,$s5

placement:
	lb $t0,($a0)
	beq $t0,10,parcours
	add $a0,$a0,1
	j placement

parcours:	
	lb $t0,($a0)
	add $a0,$a0,1
	bne $t0,10,save
	j verif

save:
	sb $t0,($t2)
	add $t2,$t2,1	
	j parcours

verif:
	beq $t3,$s6,fin
	add $t3,$t3,1
	j parcours
	
fin:
	jr $ra

#----------------------------------#
#func :closefile
#param : $a0 nom file
#return : -
# ferme un fichier
#---------------------------------#

closefile:
	li $v0,16
	syscall
	jr $ra


#-----------------------------------#
#func : printarray
#arg : $a0 tableau à afficher
#return : -
#reg mod :$a0,$v0,$t[0-2]
#-----------------------------------#
printarray:	
	li $t1,0
	li $t2,0
	li $v0,11
	move $t0,$a0

printline:
		
	lb $a0,($t0)
	syscall
	add $t0,$t0,1
	add $t1,$t1,1
	add $t2,$t2,1
	beq $t1,$s4,endprint
	beq $t2,$s7,newline 
	j printline

endprint:
	li $a0,10
	syscall 
	syscall
	jr $ra
	
newline:
	li $a0,10
	syscall
	li $t2,0
	j printline




#--------------------------------------#
#func:jeu de la vie
#args:$a0 tableau à traiter
#reg mod: $t0,$s2,$a[0-1]
#
#utilise check_voisin,check_etat_suivant
#--------------------------------------#
jeudelavie:
	
	move $t0,$a0	
	sub $sp,$sp,4
	sw $ra,0($sp)
	
	
cellcheck:
	sub $a0,$t0,$s5 #$a0 est l'indice de la cellule traiter
	div $a1,$a0,$s7		#a1 est la ligne actuelle
	beq $a0,$s4,finjeu

	jal check_voisins  #retour dans $v0 : nombre de voisin
	move $a0,$v0		#met le nombre de voisins dans $a0
	
	jal check_etat_suivant
	add $s2,$s2,1
	add $t0,$t0,1
	j cellcheck
finjeu:
	lw $ra,0($sp)
	add $sp,$sp,4
	sub $s2,$s2,$s4
	jr $ra
	
#---------------------------------------------- #
#func: check_voisin
#arg : -
#retour : $v0 (nombre de cellules voisines vivantes)
#reg mod : $t[1-2],$v[0-1]
#-----------------------------------------------#
check_voisins:
	move $t1,$a0
	move $t2,$a1
	sub $sp,$sp,4
	sw $ra,0($sp)
	li $v1,0
	jal voisin_haut
	add $v1,$v1,$v0 #avec $v0 le retour de voisin haut
	jal voisin_bas		
	add $v1,$v1,$v0
	jal voisin_gauche
	add $v1,$v1,$v0
	jal voisin_droite
	add $v1,$v1,$v0
	jal voisin_dhd
	add $v1,$v1,$v0
	jal voisin_dhg
	add $v1,$v1,$v0
	jal voisin_dbd
	add $v1,$v1,$v0
	jal voisin_dbg
	add $v1,$v1,$v0
	move $v0,$v1
	lw $ra,0($sp)
	add $sp,$sp,4
	jr $ra

#-------------------------------------------------#
#func:check_etat_suivant
#arg : $a0 nombre de cellules voisines vivantes
#reg mod : $t4
#met une cellule vivante ou morte en $s2 en fonction
#du nombre de cellules voisines vivantes
#------------------------------------------------- #
check_etat_suivant:
	beq $a0,3,vie
	beq $a0,2,copie	
	sb $s0,($s2)	
	jr $ra
	
	vie: 	
	sb $s1,($s2)
	jr $ra

	copie:
	lb $t4,($t0)
	sb $t4,($s2)
	jr $ra
	
#---------------------------------------------------#
#func : voisin_haut   
#args :
#retour : $v0 état de la cellules voisine en haut
#reg mod : $t7;$a0;$a1,$t5,$v0
#---------------------------------------------------#
voisin_haut: 
	sub $sp,$sp,4
	sw $ra,0($sp)		#sauvegarde sde $ra
	li $t7,1		
	sub $a0,$t1,$s7
	move $a1,$s4
	jal modulo 
	move $a0,$v0
	add $a0,$a0,$s5
	lb $t5,($a0)		#load le byte de a0 dans t5
	beq $t5,$s1,retourh	#si la cellule est vivante, retour
	li $t7,0		
retourh: 
	lw $ra,0($sp)
	add $sp,$sp,4
	move $v0,$t7
	jr $ra			#on renvoie 0

#---------------------------------------------------#
#func : voisin_bas 
#retour : $v0 etat de la cellule voisine en bas
#reg mod : $t7;$a0;$a1,$t5,$v0
#---------------------------------------------------#
voisin_bas:
	sub $sp,$sp,4
	sw $ra,0($sp)
	li $t7,1
	add $a0,$t1,$s7
	move $a1,$s4
	jal modulo 
	move $a0,$v0
	add $a0,$a0,$s5
	lb $t5,($a0)
	beq $t5,$s1,retourb
	li $t7,0
retourb:
	lw $ra,($sp)
	add $sp,$sp,4
	move $v0,$t7
	jr $ra

#---------------------------------------------------#
#func : voisin_gauche   
#retour : $v0 etat de la cellule voisine à gauche
#reg mod : $t7;$a0;$a1,$t5,$v0
#---------------------------------------------------#	
voisin_gauche:
	sub $sp,$sp,4
	sw $ra,0($sp)	
	li $t7,1
	sub $a0,$t1,1
	move $a1,$s7
	jal modulo
	move $a0,$v0
	add $a0,$a0,$s5
	mul $t5,$s7,$t2
	add $a0,$a0,$t5
	lb $t5,($a0)
	beq $t5,$s1,retourg
	li $t7,0
retourg:
	lw $ra,0($sp)
	add $sp,$sp,4
	move $v0,$t7
	jr $ra


#---------------------------------------------------#
#func : voisin_droite 
#retour: $v0 état de la cellule voisine à droite
#reg mod : $t7;$a0;$a1,$t5,$v0
#---------------------------------------------------#
	
voisin_droite:
	sub $sp,$sp,4
	sw $ra,0($sp)
	li $t7,1
	add $a0,$t1,1
	move $a1,$s7
	jal modulo
	move $a0,$v0
	add $a0,$a0,$s5
	mul $t5,$s7,$t2
	add $a0,$a0,$t5
	lb $t5,($a0)
	beq $t5,$s1,retourd
	li $t7,0
retourd:
	lw $ra,0($sp)
	add $sp,$sp,4
	move $v0,$t7
	jr $ra

#---------------------------------------------------#
#func : voisin_dhg   
#retour : $v0 état de la cellule voisine (haut-gauche)
#reg mod : $t7;$a0;$a1,$t5,$v0
#---------------------------------------------------#
voisin_dhg:
	sub $sp,$sp,4
	sw $ra,0($sp)
	li $t7,1
	sub $a0,$t1,1
	move $a1,$s7
	jal modulo
	move $a0,$v0
	sub $t5,$t2,1
	mul $t5,$t5,$s7
	add $a0,$a0,$t5
	move $a1,$s4
	jal modulo
	move $a0,$v0
	add $a0,$a0,$s5	
	lb $t5,($a0)
	beq $t5,$s1,retourdhg
	li $t7,0
retourdhg:
	lw $ra,0($sp)
	add $sp,$sp,4
	move $v0,$t7
	jr $ra
	
#---------------------------------------------------#
#func : voisin_dhd 
#retour : $v0 état de la cellule voisine (haut droite)
#reg mod : $t7;$a0;$a1,$t5,$v0
#---------------------------------------------------#
voisin_dhd:
	sub $sp,$sp,4
	sw $ra,0($sp)
	li $t7,1
	add $a0,$t1,1
	move $a1,$s7
	jal modulo
	move $a0,$v0
	sub $t5,$t2,1
	mul $t5,$t5,$s7
	add $a0,$a0,$t5
	move $a1,$s4
	jal modulo
	move $a0,$v0
	add $a0,$a0,$s5
	lb $t5,($a0)
	beq $t5,$s1,retourdhd
	li $t7,0
retourdhd:
	lw $ra,0($sp)
	add $sp,$sp,4
	move $v0,$t7
	jr $ra
#---------------------------------------------------#
#func : voisin_dbg   
#retour : $v0 état de la cellule voisine (bas gauche)
#reg mod : $t7;$a0;$a1,$t5,$v0
#---------------------------------------------------#
voisin_dbg:
	li $t7,1
	sub $sp,$sp,4
	sw $ra,0($sp)
	sub $a0,$t1,1
	move $a1,$s7
	jal modulo
	move $a0,$v0
	add $t5,$t2,1
	mul $t5,$t5,$s7
	add $a0,$a0,$t5
	move $a1,$s4
	jal modulo
	move $a0,$v0
	add $a0,$a0,$s5
	lb $t5,($a0)
	beq $t5,$s1,retourdbg
	li $t7,0
retourdbg:
	lw $ra,0($sp)
	add $sp,$sp,4
	move $v0,$t7
	jr $ra

#---------------------------------------------------#
#func : voisin_dbd  
#retour : $v0 état de la cellule voisin (bas droite)
#reg mod : $t7;$a0;$a1,$t5,$v0
#---------------------------------------------------#
voisin_dbd:
	li $t7,1
	sub $sp,$sp,4
	sw $ra,0($sp)
	add $a0,$t1,1
	move $a1,$s7
	jal modulo
	move $a0,$v0
	add $t5,$t2,1
	mul $t5,$t5,$s7
	add $a0,$a0,$t5
	move $a1,$s4
	jal modulo
	move $a0,$v0
	add $a0,$a0,$s5
	lb $t5,($a0)
	beq $t5,$s1,retourdbd
	li $t7,0
retourdbd:
	lw $ra,0($sp)
	add $sp,$sp,4
	move $v0,$t7
	jr $ra

#---------------------------------------------------#
#func : voisin_exit 
# met fin au programme
#reg mod : $v0
#---------------------------------------------------#
exit:
	li $v0,10
	syscall


#---------------------------------------------------#
#func : modulo   
#args : $a0 ,$a1
#retour : $v0
#reg mod : $v0
# fait $a0 mod $a1
#---------------------------------------------------#
modulo :
	rem $v0,$a0,$a1
	bgez $v0,finmod
	add $v0,$v0,$a1

finmod:	jr $ra

#------------------------------------------------#
#func : check_chg
#args : $a0,$a1
#reg used :$a0,$a1,$t8
#retour: $v0
#
#Vérifier l'égalité entre deux tableaux
#------------------------------------------------#
check_chg:
	li $t3,1
check:
	lb $t1,($a0)
	lb $t2,($a1)
	bne $t1,$t2,non_stable
	beq $t3,$s4,stable
	add $t3,$t3,1
	add $a0,$a0,1
	add $a1,$a1,1
	j check
non_stable:
	li $v0,0
	jr $ra
stable:
	li $v0,1
	jr $ra

