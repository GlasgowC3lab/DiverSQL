select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 820 and 820+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'steel' or i_color = 'lace') and 
        (i_units = 'Dram' or i_units = 'Bunch') and
        (i_size = 'medium' or i_size = 'N/A')
        ) or
        (i_category = 'Women' and
        (i_color = 'burlywood' or i_color = 'blue') and
        (i_units = 'N/A' or i_units = 'Dozen') and
        (i_size = 'petite' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'saddle' or i_color = 'navajo') and
        (i_units = 'Gram' or i_units = 'Pallet') and
        (i_size = 'small' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'peach' or i_color = 'olive') and
        (i_units = 'Cup' or i_units = 'Case') and
        (i_size = 'medium' or i_size = 'N/A')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'slate' or i_color = 'tan') and 
        (i_units = 'Tbl' or i_units = 'Bundle') and
        (i_size = 'medium' or i_size = 'N/A')
        ) or
        (i_category = 'Women' and
        (i_color = 'rosy' or i_color = 'ghost') and
        (i_units = 'Gross' or i_units = 'Ton') and
        (i_size = 'petite' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'cyan' or i_color = 'firebrick') and
        (i_units = 'Oz' or i_units = 'Pound') and
        (i_size = 'small' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'papaya' or i_color = 'wheat') and
        (i_units = 'Lb' or i_units = 'Ounce') and
        (i_size = 'medium' or i_size = 'N/A')
        )))) > 0
 order by i_product_name
 limit 100
