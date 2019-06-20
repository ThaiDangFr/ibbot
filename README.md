# IBBOT
* Current state of your portfolio
* Scrape simulation and extract the target stocks
* Rebalance : buy and sell orders
* Trade
* Crontab compliant

```
run_perso.sh and run_pro.sh : run the rebalance, and buy/sell for two portfolio
run_test : perform a test and send an email if something is wrong

you can crontab like this :

00 12 1,3,5 * * /home/ibbot/github/ibbot/run_perso.sh 
00 12 2,4,6 * * /home/ibbot/github/ibbot/run_pro.sh 
00 07,21 * * * /home/ibbot/github/ibbot/run_test.sh

or if you use dashboard functionality :
30 21  1,2,3,4 * * /home/ibbot/github/ibbot/run_dashboard.sh

perform a test before running the buy/sell
perform another test 1h before the market is closed in order to correct things if needed
```
