WITH hourly_sales AS (
    SELECT
        td.t_hour,
        td.t_shift,
        COUNT(DISTINCT ss.ss_ticket_number) AS num_tickets,
        SUM(ss.ss_net_profit) AS total_net_profit,
        AVG(ss.ss_ext_discount_amt) AS avg_discount_amt,
        SUM(ss.ss_quantity) AS total_quantity
    FROM store_sales ss
    JOIN time_dim td
        ON ss.ss_sold_time_sk = td.t_time_sk
    WHERE ss.ss_coupon_amt >= 1000.00
      AND ss.ss_ext_sales_price > 200.00
    GROUP BY td.t_hour, td.t_shift
    HAVING SUM(ss.ss_net_profit) > 0
)
SELECT
    t_hour,
    t_shift,
    num_tickets,
    total_net_profit,
    avg_discount_amt,
    total_quantity,
    RANK() OVER (ORDER BY total_net_profit DESC) AS profit_rank
FROM hourly_sales
ORDER BY total_net_profit DESC
LIMIT 10
