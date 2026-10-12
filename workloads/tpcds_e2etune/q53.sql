WITH cat_ret AS (
    SELECT d.d_year,
           d.d_month_seq AS month_seq,
           i.i_category AS category,
           hd.hd_buy_potential AS buy_potential,
           SUM(cr.cr_net_loss) AS cat_net_loss,
           COUNT(*) AS cat_return_cnt
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN household_demographics hd ON cr.cr_returning_hdemo_sk = hd.hd_demo_sk
    WHERE d.d_year BETWEEN 2015 AND 2020
    GROUP BY d.d_year, d.d_month_seq, i.i_category, hd.hd_buy_potential
),
web_ret AS (
    SELECT d.d_year,
           d.d_month_seq AS month_seq,
           i.i_category AS category,
           hd.hd_buy_potential AS buy_potential,
           SUM(wr.wr_net_loss) AS web_net_loss,
           COUNT(*) AS web_return_cnt
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN household_demographics hd ON wr.wr_returning_hdemo_sk = hd.hd_demo_sk
    WHERE d.d_year BETWEEN 2015 AND 2020
    GROUP BY d.d_year, d.d_month_seq, i.i_category, hd.hd_buy_potential
)
SELECT cat.d_year,
       cat.month_seq,
       cat.category,
       cat.buy_potential,
       cat.cat_net_loss,
       web.web_net_loss,
       (cat.cat_net_loss + COALESCE(web.web_net_loss, 0)) AS total_net_loss,
       cat.cat_return_cnt,
       COALESCE(web.web_return_cnt, 0) AS web_return_cnt,
       RANK() OVER (PARTITION BY cat.d_year, cat.month_seq ORDER BY (cat.cat_net_loss + COALESCE(web.web_net_loss, 0)) DESC) AS category_rank
FROM cat_ret cat
LEFT JOIN web_ret web
  ON cat.d_year = web.d_year
 AND cat.month_seq = web.month_seq
 AND cat.category = web.category
 AND cat.buy_potential = web.buy_potential
ORDER BY cat.d_year, cat.month_seq, category_rank
LIMIT 200
