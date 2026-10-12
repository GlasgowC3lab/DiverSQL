SELECT
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    SUM(ss.ss_net_paid) AS total_sales_net_paid,
    SUM(ss.ss_net_profit) AS total_sales_net_profit,
    COALESCE(SUM(sr.sr_net_loss), 0) AS total_returns_net_loss,
    SUM(ss.ss_net_profit) - COALESCE(SUM(sr.sr_net_loss), 0) AS net_profit_after_returns,
    COALESCE(SUM(sr.sr_return_quantity), 0) / NULLIF(SUM(ss.ss_quantity), 0) AS return_rate,
    RANK() OVER (ORDER BY SUM(ss.ss_net_profit) - COALESCE(SUM(sr.sr_net_loss), 0) DESC) AS profit_rank
FROM
    store_sales ss
JOIN
    customer_demographics cd
      ON ss.ss_cdemo_sk = cd.cd_demo_sk
LEFT JOIN
    store_returns sr
      ON ss.ss_ticket_number = sr.sr_ticket_number
     AND ss.ss_item_sk = sr.sr_item_sk
WHERE
    ss.ss_wholesale_cost > 10
    AND cd.cd_gender IN ('M', 'F')
GROUP BY
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status
HAVING
    SUM(ss.ss_net_paid) > 1000
ORDER BY
    net_profit_after_returns DESC
LIMIT 100
