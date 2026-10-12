WITH store_month_sales AS (
    SELECT
        s.s_store_sk,
        s.s_store_id,
        s.s_store_name,
        s.s_street_number,
        s.s_street_name,
        s.s_street_type,
        s.s_city,
        s.s_state,
        s.s_zip,
        substr(CAST(d.d_date AS VARCHAR), 1, 7) AS year_month,
        i.i_brand,
        lower(i.i_brand) AS lower_brand,
        i.i_product_name,
        trim(regexp_replace(i.i_product_name, '[^A-Za-z0-9 ]', '')) AS clean_product_name,
        ss.ss_net_profit,
        ss.ss_quantity
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_date >= DATE '2000-01-01'
)
SELECT
    sm.s_store_id,
    upper(sm.s_store_name) AS store_name_upper,
    concat_ws(
        ', ',
        concat_ws(' ', sm.s_street_number, sm.s_street_name, sm.s_street_type),
        sm.s_city,
        sm.s_state,
        sm.s_zip
    ) AS store_address,
    sm.year_month,
    sum(sm.ss_net_profit) AS total_net_profit,
    avg(sm.ss_net_profit) AS avg_net_profit,
    array_join(array_agg(DISTINCT sm.lower_brand ORDER BY sm.lower_brand), ', ') AS brand_list,
    (
        SELECT array_join(
            array_agg(
                concat_ws(' (', p.clean_product_name, CAST(p.product_qty AS VARCHAR), ')')
                ORDER BY p.product_qty DESC
            ),
            ', '
        )
        FROM (
            SELECT
                sm2.clean_product_name,
                sum(sm2.ss_quantity) AS product_qty
            FROM store_month_sales sm2
            WHERE sm2.s_store_id = sm.s_store_id
              AND sm2.year_month = sm.year_month
            GROUP BY sm2.clean_product_name
        ) p
    ) AS top_products
FROM store_month_sales sm
GROUP BY
    sm.s_store_id,
    sm.s_store_name,
    sm.s_street_number,
    sm.s_street_name,
    sm.s_street_type,
    sm.s_city,
    sm.s_state,
    sm.s_zip,
    sm.year_month
