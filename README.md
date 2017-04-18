Mathraining
============
[![Build Status](https://secure.travis-ci.org/blegat/mathraining.png)](http://travis-ci.org/blegat/mathraining)
[![codecov](https://codecov.io/gh/blegat/mathraining/branch/master/graph/badge.svg)](https://codecov.io/gh/blegat/mathraining)

Description
-----------
Code source de [Mathraining](http://www.mathraining.be),
le site interactif d'entraînement aux Olympiades Internationales de Mathématiques.

Vous êtes libres et encouragés à participer à son développement en soumettant
des bugs, suggestions ou même en participant à l'écriture du site web.

Si vous ne connaissez pas Git,
lisez la partie *Utilisation linéaire de Git* de
[ce tutoriel](http://sites.uclouvain.be/SystInfo/notes/Outils/html/git.html)
écrit par Benoît Legat.

To test the website locally, do
```sh
$ rake db:migrate
$ rails s
```
To run tests, do
```sh
$ rake db:migrate
$ rake db:test:prepare
$ rspec .
```
