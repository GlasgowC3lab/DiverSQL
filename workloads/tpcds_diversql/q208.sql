WITH base AS (
    SELECT
        d.d_date_sk,
        d.d_year,
        ss.ss_quantity,
        ss.ss_ext_sales_price,
        ss.ss_sales_price,
        ss.ss_ticket_number,
        i.i_brand,
        i.i_category,
        i.i_current_price,
        p.p_discount_active,
        s.s_store_name,
        s.s_state,
        c.c_customer_id,
        ca.ca_city,
        cd.cd_gender,
        hd.hd_buy_potential,
        sr.sr_return_quantity,
        sr.sr_net_loss,
        cr.cr_return_amount,
        cr.cr_net_loss AS cr_net_loss,
        inv.inv_quantity_on_hand,
        cp.cp_catalog_number,
        cp.cp_type,
        wp.wp_url,
        wp.wp_type
    FROM date_dim d
    JOIN store_sales ss
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
    JOIN inventory inv
        ON inv.inv_item_sk = i.i_item_sk
        AND inv.inv_date_sk = d.d_date_sk
    JOIN catalog_returns cr
        ON cr.cr_item_sk = i.i_item_sk
        AND cr.cr_returned_date_sk = d.d_date_sk
    JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN web_page wp
        ON wp.wp_customer_sk = c.c_customer_sk
        AND wp.wp_creation_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND i.i_current_price > 20.00
      AND s.s_state = 'CA'
      AND ca.ca_city = 'Los Angeles'
)
SELECT
    d_year,
    i_brand,
    i_category,
    s_store_name,
    SUM(ss_quantity) AS total_units_sold,
    SUM(ss_ext_sales_price) AS total_sales,
    AVG(ss_sales_price) AS avg_unit_price,
    COUNT(DISTINCT ss_ticket_number) AS distinct_transactions,
    SUM(sr_return_quantity) AS total_return_qty,
    SUM(sr_net_loss) AS total_return_loss,
    SUM(cr_return_amount) AS total_catalog_return_amount,
    SUM(cr_net_loss) AS total_catalog_return_loss,
    MAX(inv_quantity_on_hand) AS max_inventory_on_hand,
    MIN(p_discount_active) FILTER (WHERE p_discount_active IS NOT NULL) AS any_discount_active_flag
FROM base
GROUP BY
    d_year,
    i_brand,
    i_category,
    s_store_name
ORDER BY
    total_sales DESC
LIMIT 100
