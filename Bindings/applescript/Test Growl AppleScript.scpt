FasdUAS 1.101.10   ��   ��    k             i         I      �������� @0 getphotofromaddressbookroutine getPhotoFromAddressBookRoutine��  ��    k      	 	  
  
 O         r        n    	    1    	��
�� 
az50  1    ��
�� 
az54  o      ���� 0 	icon_data    m       �                                                                                  adrb  alis    h  Macintosh SSD              ��mH+   �%Address Book.app                                                -�� T        ����  	                Applications    �8�      � Q�     �%  ,Macintosh SSD:Applications: Address Book.app  "  A d d r e s s   B o o k . a p p    M a c i n t o s h   S S D  Applications/Address Book.app   / ��     ��  L       o    ���� 0 	icon_data  ��        l     ��������  ��  ��     ��  l   = ����  O    =    k   <       l   ��  ��    1 + Make a list of all the notification types      �     V   M a k e   a   l i s t   o f   a l l   t h e   n o t i f i c a t i o n   t y p e s     ! " ! l   �� # $��   # ' ! that this script will ever send:    $ � % % B   t h a t   t h i s   s c r i p t   w i l l   e v e r   s e n d : "  & ' & r    
 ( ) ( l 	   *���� * J     + +  , - , m     . . � / / " T e s t   N o t i f i c a t i o n -  0�� 0 m     1 1 � 2 2 2 A n o t h e r   T e s t   N o t i f i c a t i o n��  ��  ��   ) l      3���� 3 o      ���� ,0 allnotificationslist allNotificationsList��  ��   '  4 5 4 l   ��������  ��  ��   5  6 7 6 l   �� 8 9��   8 ( " Make a list of the notifications     9 � : : D   M a k e   a   l i s t   o f   t h e   n o t i f i c a t i o n s   7  ; < ; l   �� = >��   = - ' that will be enabled by default.          > � ? ? N   t h a t   w i l l   b e   e n a b l e d   b y   d e f a u l t .             <  @ A @ l   �� B C��   B 9 3 Those not enabled by default can be enabled later     C � D D f   T h o s e   n o t   e n a b l e d   b y   d e f a u l t   c a n   b e   e n a b l e d   l a t e r   A  E F E l   �� G H��   G 7 1 in the 'Applications' tab of the growl prefpane.    H � I I b   i n   t h e   ' A p p l i c a t i o n s '   t a b   o f   t h e   g r o w l   p r e f p a n e . F  J K J r     L M L l 	   N���� N J     O O  P�� P m     Q Q � R R " T e s t   N o t i f i c a t i o n��  ��  ��   M l      S���� S o      ���� 40 enablednotificationslist enabledNotificationsList��  ��   K  T U T l   ��������  ��  ��   U  V W V l   �� X Y��   X &   Register our script with growl.    Y � Z Z @   R e g i s t e r   o u r   s c r i p t   w i t h   g r o w l . W  [ \ [ l   �� ] ^��   ] 7 1 You can optionally (as here) set a default icon     ^ � _ _ b   Y o u   c a n   o p t i o n a l l y   ( a s   h e r e )   s e t   a   d e f a u l t   i c o n   \  ` a ` l   �� b c��   b ' ! for this script's notifications.    c � d d B   f o r   t h i s   s c r i p t ' s   n o t i f i c a t i o n s . a  e f e I   ���� g
�� .registernull��� ��� null��   g �� h i
�� 
appl h l 	   j���� j m     k k � l l 0 G r o w l   A p p l e S c r i p t   S a m p l e��  ��   i �� m n
�� 
anot m l 
   o���� o o    ���� ,0 allnotificationslist allNotificationsList��  ��   n �� p q
�� 
dnot p l 
   r���� r o    ���� 40 enablednotificationslist enabledNotificationsList��  ��   q �� s��
�� 
iapp s m     t t � u u  S c r i p t   E d i t o r��   f  v w v l   ��������  ��  ��   w  x y x l   �� z {��   z #        Send a Notification...    { � | | :               S e n d   a   N o t i f i c a t i o n . . . y  } ~ } l   ��������  ��  ��   ~   �  l   ��������  ��  ��   �  � � � l   �� � ���   �  
	No icon.	    � � � �  	 N o   i c o n . 	 �  � � � I   6���� �
�� .notifygrnull��� ��� null��   � �� � �
�� 
name � l 	 ! " ����� � m   ! " � � � � � " T e s t   N o t i f i c a t i o n��  ��   � �� � �
�� 
titl � l 	 % ( ����� � m   % ( � � � � � " T e s t   N o t i f i c a t i o n��  ��   � �� � �
�� 
desc � l 	 + . ����� � m   + . � � � � � . N o   i c o n   p r o v i d e d   b y   u s .��  ��   � �� ���
�� 
appl � m   / 2 � � � � � 0 G r o w l   A p p l e S c r i p t   S a m p l e��   �  � � � l  7 7��������  ��  ��   �  � � � l  7 7�� � ���   �  	Absolute path icon.	    � � � � * 	 A b s o l u t e   p a t h   i c o n . 	 �  � � � I  7 X���� �
�� .notifygrnull��� ��� null��   � �� � �
�� 
name � l 	 9 < ����� � m   9 < � � � � � " T e s t   N o t i f i c a t i o n��  ��   � �� � �
�� 
titl � l 	 ? B ����� � m   ? B � � � � � " T e s t   N o t i f i c a t i o n��  ��   � �� � �
�� 
desc � l 	 E H ����� � m   E H � � � � � * I c o n   f r o m   P O S I X   p a t h .��  ��   � �� � �
�� 
appl � m   I L � � � � � 0 G r o w l   A p p l e S c r i p t   S a m p l e � �� ���
�� 
iurl � m   O R � � � � � � / S y s t e m / L i b r a r y / C o r e S e r v i c e s / l o g i n w i n d o w . a p p / C o n t e n t s / R e s o u r c e s / L o g O u t . p n g��   �  � � � l  Y Y��������  ��  ��   �  � � � l  Y Y�� � ���   �  	 icon from alias.	    � � � � & 	   i c o n   f r o m   a l i a s . 	 �  � � � I  Y ~���� �
�� .notifygrnull��� ��� null��   � �� � �
�� 
name � l 	 [ ^ ����� � m   [ ^ � � � � � " T e s t   N o t i f i c a t i o n��  ��   � �� � �
�� 
titl � l 	 a d ����� � m   a d � � � � � " T e s t   N o t i f i c a t i o n��  ��   � �� � �
�� 
desc � l 	 g j ����� � m   g j � � � � �   I c o n   f r o m   a l i a s .��  ��   � �� � �
�� 
appl � m   k n � � � � � 0 G r o w l   A p p l e S c r i p t   S a m p l e � �� ���
�� 
iurl � l  q x ����� � c   q x � � � m   q t � � � � � � : S y s t e m : L i b r a r y : C o r e S e r v i c e s : l o g i n w i n d o w . a p p : C o n t e n t s : R e s o u r c e s : L o g O u t . p n g � m   t w��
�� 
alis��  ��  ��   �  � � � l   ��������  ��  ��   �  � � � l   �� � ���   �  		delay 10    � � � �  	 d e l a y   1 0 �  � � � l   ��������  ��  ��   �  � � � l   �� � ���   �  	Icon Of File    � � � �  	 I c o n   O f   F i l e �  � � � I   ���~ �
� .notifygrnull��� ��� null�~   � �} � �
�} 
name � l 	 � � ��|�{ � m   � � � � � � � " T e s t   N o t i f i c a t i o n�|  �{   � �z � �
�z 
titl � l 	 � � ��y�x � m   � � � � � � � " T e s t   N o t i f i c a t i o n�y  �x   � �w � �
�w 
desc � l 	 � � ��v�u � m   � � � � � � � 4 I c o n   o f   F i l e .   ( a n d   S t i c k y )�v  �u   � �t � �
�t 
appl � m   � �   � 0 G r o w l   A p p l e S c r i p t   S a m p l e � �s
�s 
ifil m   � � �  ~ / �r�q
�r 
stck m   � ��p
�p boovtrue�q   �  l  � ��o�n�m�o  �n  �m   	
	 l  � ��l�l    icon from application    � * i c o n   f r o m   a p p l i c a t i o n
  I  � ��k�j
�k .notifygrnull��� ��� null�j   �i
�i 
name l 	 � ��h�g m   � � � " T e s t   N o t i f i c a t i o n�h  �g   �f
�f 
titl l 	 � ��e�d m   � � � " T e s t   N o t i f i c a t i o n�e  �d   �c
�c 
desc l 	 � ��b�a m   � � �  M e s s a g e   3�b  �a   �` !
�` 
appl  m   � �"" �## 0 G r o w l   A p p l e S c r i p t   S a m p l e! �_$�^
�_ 
iapp$ m   � �%% �&&  i T u n e s . a p p�^   '(' l  � ��]�\�[�]  �\  �[  ( )*) l  � ��Z+,�Z  +  
TIFF Image   , �--  T I F F   I m a g e* ./. r   � �010 n  � �232 I   � ��Y�X�W�Y @0 getphotofromaddressbookroutine getPhotoFromAddressBookRoutine�X  �W  3  f   � �1 o      �V�V 0 tiffdata TIFFdata/ 454 I  � ��U�T6
�U .notifygrnull��� ��� null�T  6 �S78
�S 
name7 l 	 � �9�R�Q9 m   � �:: �;; 2 A n o t h e r   T e s t   N o t i f i c a t i o n�R  �Q  8 �P<=
�P 
titl< l 	 � �>�O�N> m   � �?? �@@ V T h i s   i s   a   N o t i f i c a t i o n   w i t h   T I F F   I m a g e   D a t a�O  �N  = �MAB
�M 
descA l 	 � �C�L�KC m   � �DD �EE 2 W e   a r e   u s i n g   T I F F   d a t a . . .�L  �K  B �JFG
�J 
applF m   � �HH �II 0 G r o w l   A p p l e S c r i p t   S a m p l eG �IJ�H
�I 
imagJ o   � ��G�G 0 tiffdata TIFFdata�H  5 KLK l  � ��F�E�D�F  �E  �D  L MNM l  � ��COP�C  O  coalescing	   P �QQ  c o a l e s c i n g 	N RSR I  ��B�AT
�B .notifygrnull��� ��� null�A  T �@UV
�@ 
nameU l 	 � �W�?�>W m   � �XX �YY " T e s t   N o t i f i c a t i o n�?  �>  V �=Z[
�= 
titlZ l 	 � �\�<�;\ m   � �]] �^^ " T e s t   N o t i f i c a t i o n�<  �;  [ �:_`
�: 
desc_ l 	 �a�9�8a m   �bb �cc  M e s s a g e   1�9  �8  ` �7de
�7 
appld m  ff �gg 0 G r o w l   A p p l e S c r i p t   S a m p l ee �6h�5
�6 
idenh m  	ii �jj  i d�5  S klk l �4�3�2�4  �3  �2  l mnm I �1o�0
�1 .sysodelanull��� ��� nmbro m  �/�/ �0  n pqp I :�.�-r
�. .notifygrnull��� ��� null�-  r �,st
�, 
names l 	u�+�*u m  vv �ww " T e s t   N o t i f i c a t i o n�+  �*  t �)xy
�) 
titlx l 	!$z�(�'z m  !${{ �|| " T e s t   N o t i f i c a t i o n�(  �'  y �&}~
�& 
desc} l 	'*�%�$ m  '*�� ���  M e s s a g e   2�%  �$  ~ �#��
�# 
appl� m  +.�� ��� 0 G r o w l   A p p l e S c r i p t   S a m p l e� �"��!
�" 
iden� m  14�� ���  i d�!  q �� � l ;;����  �  �  �     m     ���                                                                                  GRRR  alis    �  Perm                       �JΏH+  �	Growl.app                                                      	���p�'        ����  	                Debug     �K�      �p�g    � ��� �o9 �� ��  ��  =Perm:Users: rudy: Desktop: growl-dev: build: Debug: Growl.app    	 G r o w l . a p p  
  P e r m  3/Users/rudy/Desktop/growl-dev/build/Debug/Growl.app   /Volumes/Perm    ��  ��  ��  ��       �����  � ��� @0 getphotofromaddressbookroutine getPhotoFromAddressBookRoutine
� .aevtoappnull  �   � ****� � ������ @0 getphotofromaddressbookroutine getPhotoFromAddressBookRoutine�  �  � �� 0 	icon_data  �  ��
� 
az54
� 
az50� � 	*�,�,E�UO�� �������
� .aevtoappnull  �   � ****� k    =��  ��  �  �  �  � C� . 1� Q�� k�
�	� t��� �� �� � �� � � � �� ��  � � � � ��� � � � ������"%����:?DH��X]bf��i��v{���� ,0 allnotificationslist allNotificationsList� 40 enablednotificationslist enabledNotificationsList
� 
appl
�
 
anot
�	 
dnot
� 
iapp� 
� .registernull��� ��� null
� 
name
� 
titl
� 
desc
� .notifygrnull��� ��� null
� 
iurl�  

�� 
alis
�� 
ifil
�� 
stck�� �� @0 getphotofromaddressbookroutine getPhotoFromAddressBookRoutine�� 0 tiffdata TIFFdata
�� 
imag
�� 
iden
�� .sysodelanull��� ��� nmbr�>�:��lvE�O�kvE�O*��������� O*��a a a a �a � O*�a a a a a �a a a a  O*�a a a a a �a  a a !a "&a  O*�a #a a $a a %�a &a 'a (a )ea * O*�a +a a ,a a -�a .�a /a  O)j+ 0E` 1O*�a 2a a 3a a 4�a 5a 6_ 1a  O*�a 7a a 8a a 9�a :a ;a <a  Olj =O*�a >a a ?a a @�a Aa ;a Ba  OPUascr  ��ޭ