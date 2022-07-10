---------------------------------------------------------
-- Скрипты добавления данных
---------------------------------------------------------

-- Группы статусов
INSERT INTO dicts.status_groups (status_group) 
VALUES 
('Пользователи'), 
('Заказы'), 
('Доставка'), 
('Поставки'),
('Товары'),
('Склад'),
('Поставщики'),
('Платежи');

-- Статусы
INSERT INTO dicts.statuses (status_group_id, status_name) 
VALUES 
(1, 'Новый'), 
(1, 'Подтверждённый'), 
(1, 'Заблокирован'), 
(2, 'Новый'), 
(2, 'В обработке'),
(2, 'Оплачен'),
(2, 'Отменён пользователем'),
(2, 'Завершён'),
(3, 'Новая'),
(3, 'В пути'),
(3, 'Завершена'),
(4, 'Новая'),
(6, 'В наличии'),
(6, 'Заканчивается'),
(6, 'Отсутствует');

-- Пользователи
INSERT INTO dicts.users (last_name, first_name, middle_name, birth_date, email, password_hash, phone, gender, status_id)
VALUES
( 'Акимов', 'Юрий', 'Владимирович', '1980-10-05', 'yura.akimov.21@bk.ru', md5('123'), '8(917)121-92-92', 1, 5 ),
( 'Сайфуллин', 'Артур', 'Зиннурович', '1981-01-19', '190181@list.ru', md5('456'), '8(917)411-32-30', 1, 5 ),
( null, 'Наталья', 'Александровна', '1985-04-28', 'kovtunec@yandex.ru', md5('789'), '8(861)693-38-09', 2, 5 ),
( 'Федорова', 'Ирина', 'Васильевна', '1977-07-01', 'i.fedorova77@mail.ru', md5('234'), '8(917)120-72-08', 2, 5 ),
('Flores','Ria','Chaney','1981-01-06','curae.donec@protonmail.edu','VSV76DVI6FH','(469) 306-1666',1,5),
  ('Reynolds','Rigel','Carl','2002-01-14','fringilla.porttitor.vulputate@protonmail.ca','VOX47EBD0TD','(158) 370-4247',1,5),
  ('Meadows','Macey','Blaze','1978-10-28','enim.nisl.elementum@protonmail.org','IAV44OQK9GP','(345) 428-0282',2,5),
  ('Reyes','Leigh','Adara','1981-09-16','nam.interdum@outlook.net','SBG11JLG1PA','(412) 681-6342',2,5),
  ('Watkins','Calista','Doris','1998-06-29','sit@aol.net','VLR26JTS1UK','(244) 618-8275',1,5),
  ('Pate','Colleen','Cameron','2007-02-26','sapien.molestie@outlook.com','JKD34MLE9OW','(584) 875-7620',1,5),
  ('Mcfarland','Summer','Gary','1999-04-19','mauris.suspendisse@protonmail.net','FXY25MEU5ND','(884) 248-5745',1,5),
  ('Alston','Jakeem','Thor','1982-05-16','facilisis.magna@yahoo.org','BMG20BBO9IH','(108) 726-8397',2,5),
  ('Valenzuela','Drew','Mercedes','1974-02-13','lectus@icloud.ca','CPU64WBQ8UW','(484) 831-8663',2,5),
  ('Meyer','Camille','Steel','1969-02-18','eget.varius@icloud.net','GXC31MGB3JW','(616) 427-6872',1,5),
  ('Mckay','Melinda','Sara','1989-05-13','lobortis.risus@icloud.com','UNR91YTW1JN','(648) 788-2187',1,5),
  ('Hobbs','Ginger','Carol','1992-05-01','aliquam.eu@hotmail.net','SHX70CFR7KU','(332) 836-3341',1,5),
  ('Lowe','Karina','Ira','1982-01-12','auctor.odio.a@outlook.org','VZM56HPS6DI','(866) 326-1744',2,5),
  ('Clemons','Drew','Jasmine','1985-05-15','sapien.nunc@google.org','FJI56YLM8UB','(876) 573-4451',2,5),
  ('Fuller','Chastity','Cheyenne','1983-01-13','nec@google.org','XKI27XTH3DC','(431) 937-0015',1,5),
  ('Estes','Rebekah','Colleen','1994-07-14','nascetur@yahoo.net','PPO31QAT3II','(745) 115-5062',1,5),
  ('Foreman','Yuli','Phelan','1977-10-29','non.quam@icloud.org','MLB34NVO8NX','(528) 495-2925',1,5),
  ('Waters','Randall','Isaac','2004-06-19','erat@aol.org','EZC48IUG3HA','(355) 794-5857',2,5),
  ('Cameron','Marcia','Leigh','1985-04-30','accumsan@protonmail.couk','HSW58CVD6GX','(371) 366-4652',2,5),
  ('Schroeder','Madison','Seth','2005-07-06','ridiculus.mus@protonmail.net','ZRX98BUH3HJ','(734) 988-0388',1,5),
  ('Mitchell','Felix','Hedley','1991-12-15','sagittis@icloud.org','RGK55VEU3OO','(662) 959-0535',1,5),
  ('Blake','Victoria','Lev','2006-11-29','quis@outlook.com','LVJ44IYT3ZI','(135) 995-7837',2,5),
  ('Strong','Rafael','Lillian','1984-07-03','eleifend.nunc@icloud.net','XGA24TUE5DG','(618) 917-5747',2,5),
  ('Beach','Ferris','Francesca','2008-12-14','non@yahoo.ca','IJR48PRT8RJ','(178) 785-2084',1,5),
  ('Dudley','Kay','Denton','2006-07-08','interdum.curabitur@hotmail.edu','UUR33DVW3KD','(808) 759-4544',1,5),
  ('Bowers','Miranda','Jacob','2004-08-30','lobortis.quam@google.org','SBO29JFW2FM','(451) 540-2713',1,5),
  ('Ford','Charity','Dana','2004-03-20','metus.aenean@outlook.couk','XFK72BDU3PM','(133) 232-3167',2,5),
  ('Pugh','Clio','Gannon','1983-07-17','et@icloud.ca','KII27NLA7CQ','(856) 422-8544',2,5),
  ('Spencer','Abraham','Davis','1990-12-10','ac@hotmail.edu','KWH87HCG3XO','(643) 265-3425',1,5),
  ('Tyson','Brady','Fletcher','1965-10-20','quis.accumsan@google.couk','IBL68NYG0DY','(985) 989-4763',1,5),
  ('Case','Dieter','Alana','2008-01-24','eu.odio@hotmail.edu','FBN73KUT5CD','(713) 803-5062',1,5),
  ('Watts','Katell','Sybil','2000-04-09','curabitur@google.edu','XUY91YPC1YZ','(919) 781-6595',2,5),
  ('Case','Benjamin','Jorden','2006-10-18','gravida.sagittis@aol.net','SXR84KGH0UU','(521) 783-9196',2,5),
  ('Hernandez','Zelenia','Ora','2007-10-13','pharetra.quisque.ac@google.edu','NFM79NAP4ID','(636) 240-7951',1,5)
  ;
