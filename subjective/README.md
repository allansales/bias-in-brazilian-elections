# Subjectivity Bias

## Content

 - Data folder: contain codes to calculate rates of news text and wikipedia sample subjectivity rates
 - research_questions.Rmd: is used to make inferences about data

## Execution 

### Data generation

1. Download raw data from news portals and wikipedia.xml

2. In extract_text_from_xml: execute wikifil.pl to get wikipedia's xml and extract its text; removing tags, numbers and accents;
```
    perl wikifil.pl > <filename>
```

3. In process_text_expressions: run preprocess_expressions_tuned.sh into wikipedia, comment and news' data to manage some expressions and convert text to lower case. If <remove_punctuation> == true, the script will, also, remove the punctuation (except dot).

```
    bash preprocess_expressions_tuned.sh <filename> <remove_punctuation>
```

4) In vectors_generation: execute vectors_generation.ipynb to create word embeddings using processed wikipedia.

5) In wmd: execute word_movers_distance.ipynb passing all data and text separatedly to the script. Or alternatively, execute wmd.py passing (i) raw data, (ii) processed text, (iii) output name and (iv) the processing starting line.

```
    python wmd.py <raw_data> <processed_data> <output_name> <initial_row_number>
```

6) If want to, wiki_wmd.py calculate the rates for a sample of wikipedia's articles.

* Alternatively, we are already making available files containing a wikipedia trained model and the texts with the calculated rates.

### Experiments 

Open research_questions.Rmd in RStudio and run cells normally. Data is already being imported and processed.

## Appendix

Here, we make available, in portuguese (as used in the paper), the sets of words that were considered indicators of subjectivity:

- Argumentation: a_ponto, ao_menos, apenas, ate, ate_mesmo, incluindo, inclusive, mesmo, nao_mais_que, nem_mesmo, no_minimo, o_unico, a_unica, pelo_menos, quando_menos, quando_muito, sequer, so, somente, a_par_disso, ademais, afinal, ainda, alem, alias, como, e, e_nao, em_suma, enfim, mas_tambem, muito_menos, nao_so, nem, ou_mesmo, por_sinal, tambem, tampouco, assim, com_isso, como_consequencia, consequentemente, de_modo_que, deste_modo, em_decorrencia, entao, logicamente, logo, nesse_sentido, pois, por_causa, por_conseguinte, por_essa_razao, por_isso, portanto, sendo_assim, ou, ou_entao, ou_mesmo, nem, como_se, de_um_lado, por_outro_lado, mais_que, menos_que, nao_so, tanto, quanto, tao, como, desde_que, do_contrario, em_lugar, em_vez, enquanto, no_caso, quando, se, se_acaso, senao, de_certa_forma, desse_modo, em_funcao, enquanto, isso_e, ja_que, na_medida_que, nessa_direcao, no_intuito, no_mesmo_sentido, ou_seja, pois, porque, que, uma_vez_que, tanto_que, visto_que, ainda_que, ao_contrario, apesar_de, contrariamente, contudo, embora, entretanto, fora_isso, mas, mesmo_que, nao_obstante, nao_fosse_isso, no_entanto, para_tanto, pelo_contrario, por_sua_vez, porem, posto_que, todavia.

- Sentiment:  abalar, abater, abominar, aborrecer, acalmar, acovardar, admirar, adorar, afligir, agitar, alarmar, alegrar, alucinar, amar, ambicionar, amedrontar, amolar, animar, apavorar, apaziguar, apoquentar, aporrinhar, apreciar, aquietar, arrepender, assombrar, assustar, atazanar, atemorizar, aterrorizar, aticar, atordoar, atormentar, aturdir, azucrinar, chatear, chocar, cobicar, comover, confortar, confundir, consolar, constranger, contemplar, contentar, contrariar, conturbar, curtir, debilitar, decepcionar, depreciar, deprimir, desapontar, descontentar, descontrolar, desejar, desencantar, desencorajar, desesperar, desestimular, desfrutar, desgostar, desiludir, desinteressar, deslumbrar, desorientar, desprezar, detestar, distrair, emocionar, empolgar, enamorar, encantar, encorajar, endividar, enervar, enfeiticar, enfurecer, enganar, enraivecer, entediar, entreter, entristecer, entusiasmar, envergonhar, escandalizar, espantar, estimar, estimular, estranhar, exaltar, exasperar, excitar, execrar, fascinar, frustar, gostar, gozar, grilar, hostilizar, idolatrar, iludir, importunar, impressionar, incomodar, indignar, inibir, inquietar, intimidar, intrigar, irar, irritar, lamentar, lastimar, louvar, magoar, maravilhar, melindrar, menosprezar, odiar, ofender, pasmar, perdoar, preocupar, prezar, querer, recalcar, recear, reconfortar, rejeitar, repelir, reprimir, repudiar, respeitar, reverenciar, revoltar, seduzir, sensibilizar, serenar, simpatizar, sossegar, subestimar, sublimar, superestimar, surpreender, temer, tolerar, tranquilizar, transtornar, traumatizar, venerar.

- Modalization: achar, aconselhar, acreditar, aparente, basico, bastar, certo, claro, conveniente, crer, dever, dificil, duvida, efetivo, esperar, evidente, exato, facultativo, falar, fato, fundamental, imaginar, importante, indubitavel, inegavel, justo, limitar, logico, natural, necessario, negar, obrigatorio, obvio, parecer, pensar, poder, possivel, precisar, predominar, presumir, procurar, provavel, puder, real, recomendar, seguro, supor, talvez, tem, tendo, ter, tinha, tive, verdade, decidir.

- Pressuposition: adivinhar, admitir, agora, aguentar, ainda, antes, atentar, atual, aturar, comecar, compreender, conseguir, constatar, continuar, corrigir, deixar, demonstrar, descobrir, desculpar, desde, desvendar, detectar, entender, enxergar, esclarecer, escutar, esquecer, gabar, ignorar, iniciar, interromper, ja, lembrar, momento, notar, observar, olhar, ouvir, parar, perceber, perder, pressentir, prever, reconhecer, recordar, reparar, retirar, revelar, saber, sentir, tolerar, tratar, ver, verificar.

- Valorization: absoluto, algum, alto, amplo, aproximado, bastante, bem, bom, categorico, cerca, completo, comum, consideravel, constante, definitivo, demais, elevado, enorme, escasso, especial, estrito, eventual, exagero, excelente, excessivo, exclusivo, expresso, extremo, feliz, franco, franqueza, frequente, generalizado, geral, grande, imenso, incrivel, lamentavel, leve, maioria, mais, mal, melhor, menos, mero, minimo, minoria, muito, normal, ocasional, otimo, particular, pena, pequeno, pesar, pior, pleno, pobre, pouco, pouquissimo, praticamente, prazer, preciso, preferir, principal, quase, raro, razoavel, relativo, rico, rigor, sempre, significativo, simples, tanto, tao, tipico, total, tremenda, usual, valer.
