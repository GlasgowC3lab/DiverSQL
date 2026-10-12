WITH filtered_sales AS (
    SELECT
        ss.ss_net_profit,
        ss.ss_ext_discount_amt,
        ss.ss_quantity,
        ss.ss_sales_price,
        ss.ss_ticket_number,
        ca.ca_city,
        i.i_category,
        td.t_shift
    FROM store_sales ss
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE
        i.i_category = 'Sports'
        AND td.t_shift = 'Evening'
        AND hd.hd_buy_potential = '500-1000'
        AND ca.ca_state = 'CA'
        AND ca.ca_city IN ('Fairview', 'Glendale', 'Oak Ridge')
)
SELECT
    ca_city,
    i_category,
    t_shift,
    total_net_profit,
    total_discount,
    total_quantity,
    avg_sales_price,
    distinct_tickets,
    profit_rank
FROM (
    SELECT
        ca_city,
        i_category,
        t_shift,
        SUM(ss_net_profit) AS total_net_profit,
        SUM(ss_ext_discount_amt) AS total_discount,
        SUM(ss_quantity) AS total_quantity,
        AVG(ss_sales_price) AS avg_sales_price,
        COUNT(DISTINCT ss_ticket_number) AS distinct_tickets,
        RANK() OVER (PARTITION BY ca_city ORDER BY SUM(ss_net_profit) DESC) AS profit_rank
    FROM filtered_sales
    GROUP BY ca_city, i_category, t_shift
) ranked
WHERE profit_rank <= 3
  AND total_net_profit > 5000
ORDER BY total_net_profit DESC
LIMIT 10
