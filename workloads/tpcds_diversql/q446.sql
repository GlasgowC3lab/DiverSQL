WITH
    sampled_sales AS (
        SELECT *
        FROM store_sales
        TABLESAMPLE BERNOULLI (10)
        WHERE ss_sold_date_sk BETWEEN 2450915 AND 2451915
          AND ss_quantity > 1
    ),
    item_attrs AS (
        SELECT i_item_sk,
               array[ i_brand, i_category ] AS attrs,
               i_manufact,
               i_current_price
        FROM item
        WHERE i_brand_id IN (1003001, 2004002)
    ),
    joined_base AS (
        SELECT
            ss.ss_ticket_number,
            ss.ss_sold_date_sk,
            ss.ss_item_sk,
            ss.ss_hdemo_sk,
            ss.ss_addr_sk,
            ss.ss_store_sk,
            ss.ss_quantity,
            ss.ss_sales_price,
            ss.ss_net_paid,
            ss.ss_net_profit,
            i.i_item_id,
            i.i_product_name,
            i.i_current_price,
            ca.ca_state,
            ca.ca_city,
            hd.hd_buy_potential,
            hd.hd_dep_count,
            ib.ib_lower_bound,
            ib.ib_upper_bound,
            r.r_reason_desc,
            sr.sr_return_quantity,
            sr.sr_return_amt,
            sr.sr_net_loss
        FROM sampled_sales ss
        LEFT JOIN item i ON ss.ss_item_sk = i.i_item_sk
        LEFT JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
        LEFT JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
        LEFT JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
        FULL OUTER JOIN store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number
        LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
        WHERE i.i_category_id = 5
          AND ca.ca_state = 'CA'
          AND hd.hd_buy_potential = '1001-5000'
          AND ib.ib_lower_bound >= 20000
          AND (sr.sr_return_quantity IS NULL OR sr.sr_return_quantity > 0)
    ),
    unnested_attrs AS (
        SELECT
            jb.*,
            attr
        FROM joined_base jb
        LEFT JOIN item_attrs ia ON jb.ss_item_sk = ia.i_item_sk
        CROSS JOIN UNNEST(ia.attrs) AS t(attr)
    ),
    avg_price_per_item AS (
        SELECT ss_item_sk, AVG(ss_sales_price) AS avg_price
        FROM store_sales
        GROUP BY ss_item_sk
    )
SELECT
    ua.ss_item_sk,
    ua.i_product_name,
    ua.ca_city,
    ua.ca_state,
    ua.hd_buy_potential,
    ua.attr AS attribute,
    SUM(ua.ss_quantity) AS total_quantity,
    SUM(ua.ss_net_paid) AS total_net_paid,
    AVG(ua.ss_sales_price) AS avg_sales_price,
    COUNT(DISTINCT ua.ss_ticket_number) AS distinct_tickets,
    MAX(ua.sr_return_amt) AS max_return_amount,
    MIN(ua.sr_net_loss) AS min_net_loss,
    ap.avg_price AS overall_avg_price
FROM unnested_attrs ua
LEFT JOIN avg_price_per_item ap ON ua.ss_item_sk = ap.ss_item_sk
WHERE ua.ss_sales_price > (
        SELECT AVG(ss_sales_price)
        FROM store_sales
        WHERE ss_sold_date_sk = 2451000
    )
GROUP BY
    ua.ss_item_sk,
    ua.i_product_name,
    ua.ca_city,
    ua.ca_state,
    ua.hd_buy_potential,
    ua.attr,
    ap.avg_price

UNION DISTINCT

SELECT
    ua2.ss_item_sk,
    ua2.i_product_name,
    ua2.ca_city,
    ua2.ca_state,
    ua2.hd_buy_potential,
    ua2.attr,
    SUM(ua2.ss_quantity) AS total_quantity,
    SUM(ua2.ss_net_paid) AS total_net_paid,
    AVG(ua2.ss_sales_price) AS avg_sales_price,
    COUNT(DISTINCT ua2.ss_ticket_number) AS distinct_tickets,
    MAX(ua2.sr_return_amt) AS max_return_amount,
    MIN(ua2.sr_net_loss) AS min_net_loss,
    ap2.avg_price AS overall_avg_price
FROM unnested_attrs ua2
LEFT JOIN avg_price_per_item ap2 ON ua2.ss_item_sk = ap2.ss_item_sk
WHERE ua2.ss_sales_price > (
        SELECT AVG(ss_sales_price)
        FROM store_sales
        WHERE ss_sold_date_sk = 2451000
    )
GROUP BY
    ua2.ss_item_sk,
    ua2.i_product_name,
    ua2.ca_city,
    ua2.ca_state,
    ua2.hd_buy_potential,
    ua2.attr,
    ap2.avg_price

ORDER BY total_net_paid DESC
LIMIT 100
