SELECT
    store_id,
    num_returns,
    total_return_amount,
    total_net_loss,
    total_original_sales,
    net_loss_ratio,
    avg_fee,
    RANK() OVER (ORDER BY net_loss_ratio DESC) AS store_rank
FROM (
    SELECT
        r.sr_store_sk AS store_id,
        COUNT(*) AS num_returns,
        SUM(r.sr_return_amt) AS total_return_amount,
        SUM(r.sr_net_loss) AS total_net_loss,
        SUM(s.ss_net_paid_inc_tax) AS total_original_sales,
        SUM(r.sr_fee) AS total_fee,
        AVG(r.sr_fee) AS avg_fee,
        CASE WHEN SUM(s.ss_net_paid_inc_tax) = 0 THEN NULL
             ELSE SUM(r.sr_net_loss) / SUM(s.ss_net_paid_inc_tax)
        END AS net_loss_ratio
    FROM store_returns r
    JOIN store_sales s
      ON r.sr_item_sk = s.ss_item_sk
     AND r.sr_ticket_number = s.ss_ticket_number
    WHERE r.sr_returned_date_sk BETWEEN 2451053 AND 2452595
      AND r.sr_fee > 50
      AND r.sr_return_ship_cost > 10
      AND r.sr_customer_sk IN (102628, 2710793, 5120252)
    GROUP BY r.sr_store_sk
    HAVING SUM(r.sr_net_loss) > 500
) t
ORDER BY net_loss_ratio DESC
LIMIT 10
