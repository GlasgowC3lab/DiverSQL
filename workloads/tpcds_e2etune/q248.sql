WITH sales_by_item AS (
    SELECT
        cs.cs_item_sk,
        cs.cs_order_number,
        cs.cs_sold_date_sk,
        cs.cs_ship_mode_sk,
        cs.cs_promo_sk,
        SUM(cs.cs_net_paid_inc_ship) AS sales_amount,
        SUM(cs.cs_net_profit) AS profit,
        AVG(cs.cs_ext_discount_amt) AS avg_discount,
        COUNT(*) AS sales_cnt
    FROM catalog_sales cs
    WHERE cs.cs_sold_date_sk BETWEEN 2450816 AND 2450845
    GROUP BY cs.cs_item_sk,
             cs.cs_order_number,
             cs.cs_sold_date_sk,
             cs.cs_ship_mode_sk,
             cs.cs_promo_sk
)
SELECT
    cr.cr_returned_date_sk AS return_date,
    sb.cs_sold_date_sk AS sale_date,
    sb.cs_ship_mode_sk AS ship_mode,
    sb.cs_promo_sk AS promo_id,
    COUNT(DISTINCT cr.cr_order_number) AS distinct_returns,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_net_loss) AS total_net_loss,
    SUM(sb.sales_amount) AS total_sales_amount,
    SUM(sb.profit) AS total_sales_profit,
    AVG(sb.avg_discount) AS avg_discount_per_item,
    RANK() OVER (PARTITION BY sb.cs_sold_date_sk ORDER BY SUM(cr.cr_net_loss) DESC) AS loss_rank_by_date
FROM catalog_returns cr
JOIN sales_by_item sb
    ON cr.cr_item_sk = sb.cs_item_sk
   AND cr.cr_order_number = sb.cs_order_number
WHERE cr.cr_return_tax > 30.00
  AND cr.cr_refunded_cash BETWEEN 20.00 AND 300.00
  AND cr.cr_return_quantity > 0
GROUP BY
    cr.cr_returned_date_sk,
    sb.cs_sold_date_sk,
    sb.cs_ship_mode_sk,
    sb.cs_promo_sk
HAVING SUM(cr.cr_return_amount) > 500
ORDER BY total_net_loss DESC
LIMIT 100
