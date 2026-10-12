WITH rs AS (
    SELECT
        sr.sr_store_sk,
        sr.sr_customer_sk,
        sr.sr_returned_date_sk,
        sr.sr_return_quantity,
        sr.sr_return_amt,
        sr.sr_net_loss,
        sr.sr_store_credit,
        sr.sr_return_ship_cost,
        ss.ss_net_paid,
        ss.ss_net_profit,
        ss.ss_quantity,
        ss.ss_sales_price,
        ss.ss_ext_sales_price,
        ss.ss_ext_discount_amt,
        ss.ss_ext_tax
    FROM store_returns sr
    JOIN store_sales ss
      ON sr.sr_item_sk = ss.ss_item_sk
     AND sr.sr_ticket_number = ss.ss_ticket_number
    WHERE sr.sr_net_loss > 500
      AND sr.sr_store_credit > 500
      AND sr.sr_return_ship_cost > 100
      AND ss.ss_net_paid > 0
)
SELECT
    sr_store_sk,
    COUNT(*) AS num_returns,
    SUM(sr_return_amt) AS total_return_amount,
    SUM(sr_net_loss) AS total_net_loss,
    SUM(ss_net_paid) AS total_sales_net_paid,
    SUM(ss_net_profit) AS total_sales_net_profit,
    AVG(ss_net_profit) AS avg_sales_net_profit,
    SUM(sr_net_loss) / NULLIF(SUM(ss_net_profit), 0) AS loss_to_profit_ratio,
    RANK() OVER (ORDER BY SUM(sr_net_loss) DESC) AS loss_rank
FROM rs
GROUP BY sr_store_sk
HAVING COUNT(*) >= 5
ORDER BY loss_to_profit_ratio DESC
LIMIT 10
