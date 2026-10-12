WITH all_sales AS (
    SELECT
        ss.ss_promo_sk AS promo_sk,
        p.p_promo_name AS promo_name,
        ss.ss_customer_sk AS cust_sk,
        ss.ss_net_profit - COALESCE(sr.sr_net_loss, 0) AS net_profit,
        ss.ss_ext_discount_amt AS discount_amt,
        ss.ss_sold_date_sk AS sold_date_sk
    FROM store_sales ss
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    LEFT JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number AND sr.sr_item_sk = ss.ss_item_sk
    WHERE p.p_discount_active = 'Y'
      AND c.c_preferred_cust_flag = 'Y'
    UNION ALL
    SELECT
        cs.cs_promo_sk AS promo_sk,
        p.p_promo_name AS promo_name,
        cs.cs_bill_customer_sk AS cust_sk,
        cs.cs_net_profit AS net_profit,
        cs.cs_ext_discount_amt AS discount_amt,
        cs.cs_sold_date_sk AS sold_date_sk
    FROM catalog_sales cs
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    WHERE p.p_discount_active = 'Y'
      AND c.c_preferred_cust_flag = 'Y'
    UNION ALL
    SELECT
        ws.ws_promo_sk AS promo_sk,
        p.p_promo_name AS promo_name,
        ws.ws_bill_customer_sk AS cust_sk,
        ws.ws_net_profit AS net_profit,
        ws.ws_ext_discount_amt AS discount_amt,
        ws.ws_sold_date_sk AS sold_date_sk
    FROM web_sales ws
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE p.p_discount_active = 'Y'
      AND c.c_preferred_cust_flag = 'Y'
),
aggregated_sales AS (
    SELECT
        promo_sk,
        promo_name,
        COUNT(DISTINCT cust_sk) AS distinct_customers,
        SUM(net_profit) AS total_net_profit,
        SUM(discount_amt) AS total_discount_amount,
        ROUND(100 * SUM(net_profit) / NULLIF(SUM(net_profit) + SUM(discount_amt), 0), 2) AS profit_margin_pct
    FROM all_sales
    WHERE sold_date_sk BETWEEN 2450844 AND 2451087
    GROUP BY promo_sk, promo_name
)
SELECT
    promo_sk,
    promo_name,
    distinct_customers,
    total_net_profit,
    total_discount_amount,
    profit_margin_pct,
    RANK() OVER (ORDER BY total_net_profit DESC) AS profit_rank
FROM aggregated_sales
ORDER BY total_net_profit DESC
LIMIT 10
