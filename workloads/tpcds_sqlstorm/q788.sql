SELECT
    s.s_state,
    d.d_year,
    cd.cd_gender,
    i.i_category,
    SUM(ss.ss_net_profit) AS total_profit,
    SUM(ss.ss_quantity) AS total_quantity
FROM store_sales ss
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN item i ON ss.ss_item_sk = i.i_item_sk
WHERE d.d_year BETWEEN 2000 AND 2002
  AND s.s_state IN ('CA','TX','NY')
GROUP BY
    s.s_state,
    d.d_year,
    cd.cd_gender,
    i.i_category
ORDER BY total_profit DESC
LIMIT 100
