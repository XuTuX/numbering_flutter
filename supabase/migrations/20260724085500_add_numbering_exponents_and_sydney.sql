-- Add Sydney's exponent stages and keep exponentiation unlocked afterward.

update public.game_score_rules
set max_stage = 200, updated_at = now()
where game_id = 'numbering';

-- Preserve the meaning of existing London/Paris stage metadata after Sydney
-- is inserted at levels 81-120.
select set_config('app.numbering_verified_write', 'on', true);
update public.scores
set stage = stage + 40
where game_id = 'numbering' and stage between 81 and 160;

alter table private.numbering_level_rules
drop constraint if exists numbering_level_rules_level_id_check;
alter table private.numbering_level_rules
add constraint numbering_level_rules_level_id_check
check (level_id between 1 and 200);

-- LEVEL_RULE_VALUES_START
-- Generated from lib/game/numbering/level_catalog.dart. Do not edit by hand.
insert into private.numbering_level_rules (
  level_id, digit_string, available_operators,
  minimum_score, target_score, difficulty
)
values
  (1, '9243', array['+', '-']::text[], 5, 7, 1),
  (2, '2662', array['+', '-']::text[], 6, 8, 1),
  (3, '5647', array['+', '-']::text[], 9, 11, 1),
  (4, '9348', array['+', '-']::text[], 9, 12, 1),
  (5, '9568', array['+', '-']::text[], 11, 14, 1),
  (6, '22347', array['+', '-']::text[], 1, 2, 1),
  (7, '6455', array['+', '-']::text[], 8, 10, 1),
  (8, '4893', array['+', '-']::text[], 9, 12, 1),
  (9, '3663', array['+', '-']::text[], 7, 9, 1),
  (10, '5775', array['+', '-']::text[], 9, 12, 1),
  (11, '19217', array['+', '-']::text[], 8, 10, 1),
  (12, '93462', array['+', '-']::text[], 9, 12, 1),
  (13, '18821', array['+', '-']::text[], 7, 9, 1),
  (14, '84183', array['+', '-']::text[], 9, 12, 1),
  (15, '21511', array['+', '-']::text[], 1, 3, 1),
  (16, '15765', array['+', '-']::text[], 4, 6, 1),
  (17, '12388', array['+', '-']::text[], 1, 3, 1),
  (18, '12111', array['+', '-']::text[], 1, 3, 1),
  (19, '22185', array['+', '-']::text[], 2, 4, 1),
  (20, '26332', array['+', '-']::text[], 6, 8, 1),
  (21, '29254', array['+', '-', '×']::text[], 9, 11, 2),
  (22, '22348', array['+', '-', '×']::text[], 6, 8, 2),
  (23, '82375', array['+', '-', '×']::text[], 12, 16, 2),
  (24, '28559', array['+', '-', '×']::text[], 12, 16, 2),
  (25, '72217', array['+', '-', '×']::text[], 11, 14, 2),
  (26, '13652', array['+', '-', '×']::text[], 1, 3, 2),
  (27, '12112', array['+', '-', '×']::text[], 1, 3, 2),
  (28, '35546', array['+', '-', '×']::text[], 12, 15, 2),
  (29, '82197', array['+', '-', '×']::text[], 12, 16, 2),
  (30, '52143', array['+', '-', '×']::text[], 5, 7, 2),
  (31, '1012347', array['+', '-', '×']::text[], 5, 7, 2),
  (32, '345372', array['+', '-', '×']::text[], 18, 23, 2),
  (33, '657437', array['+', '-', '×']::text[], 5, 7, 2),
  (34, '324612', array['+', '-', '×']::text[], 2, 4, 2),
  (35, '465667', array['+', '-', '×']::text[], 15, 19, 2),
  (36, '921333', array['+', '-', '×']::text[], 21, 27, 2),
  (37, '879243', array['+', '-', '×']::text[], 7, 9, 2),
  (38, '326312', array['+', '-', '×']::text[], 4, 6, 2),
  (39, '762285', array['+', '-', '×']::text[], 20, 26, 2),
  (40, '132124', array['+', '-', '×']::text[], 4, 6, 2),
  (41, '10012349', array['+', '-', '×', '÷']::text[], 6, 8, 3),
  (42, '241934', array['+', '-', '×', '÷']::text[], 7, 10, 3),
  (43, '399136', array['+', '-', '×', '÷']::text[], 12, 18, 3),
  (44, '451343', array['+', '-', '×', '÷']::text[], 14, 21, 3),
  (45, '773256', array['+', '-', '×', '÷']::text[], 2, 4, 3),
  (46, '597119', array['+', '-', '×', '÷']::text[], 7, 10, 3),
  (47, '225113', array['+', '-', '×', '÷']::text[], 3, 5, 3),
  (48, '532541', array['+', '-', '×', '÷']::text[], 17, 25, 3),
  (49, '541721', array['+', '-', '×', '÷']::text[], 14, 21, 3),
  (50, '312122', array['+', '-', '×', '÷']::text[], 4, 6, 3),
  (51, '955472', array['+', '-', '×', '÷']::text[], 14, 20, 3),
  (52, '145438', array['+', '-', '×', '÷']::text[], 14, 20, 3),
  (53, '361235', array['+', '-', '×', '÷']::text[], 12, 17, 3),
  (54, '711911', array['+', '-', '×', '÷']::text[], 6, 9, 3),
  (55, '333993', array['+', '-', '×', '÷']::text[], 18, 27, 3),
  (56, '559811', array['+', '-', '×', '÷']::text[], 11, 16, 3),
  (57, '713317', array['+', '-', '×', '÷']::text[], 14, 21, 3),
  (58, '111223', array['+', '-', '×', '÷']::text[], 1, 3, 3),
  (59, '712711', array['+', '-', '×', '÷']::text[], 10, 14, 3),
  (60, '474214', array['+', '-', '×', '÷']::text[], 5, 7, 3),
  (61, '2174418', array['+', '-', '×', '÷']::text[], 5, 7, 3),
  (62, '4921258', array['+', '-', '×', '÷']::text[], 18, 26, 3),
  (63, '4354433', array['+', '-', '×', '÷']::text[], 4, 6, 3),
  (64, '6911166', array['+', '-', '×', '÷']::text[], 10, 14, 3),
  (65, '5151514', array['+', '-', '×', '÷']::text[], 17, 25, 3),
  (66, '8122323', array['+', '-', '×', '÷']::text[], 11, 16, 3),
  (67, '1393219', array['+', '-', '×', '÷']::text[], 18, 27, 3),
  (68, '2771321', array['+', '-', '×', '÷']::text[], 1, 3, 3),
  (69, '2928531', array['+', '-', '×', '÷']::text[], 15, 22, 3),
  (70, '4722575', array['+', '-', '×', '÷']::text[], 15, 22, 3),
  (71, '3792496', array['+', '-', '×', '÷']::text[], 8, 12, 3),
  (72, '3711357', array['+', '-', '×', '÷']::text[], 15, 22, 3),
  (73, '6324222', array['+', '-', '×', '÷']::text[], 12, 18, 3),
  (74, '1281763', array['+', '-', '×', '÷']::text[], 7, 10, 3),
  (75, '1294943', array['+', '-', '×', '÷']::text[], 18, 27, 3),
  (76, '9977871', array['+', '-', '×', '÷']::text[], 5, 7, 3),
  (77, '2451985', array['+', '-', '×', '÷']::text[], 1, 3, 3),
  (78, '3651112', array['+', '-', '×', '÷']::text[], 2, 4, 3),
  (79, '2331423', array['+', '-', '×', '÷']::text[], 12, 18, 3),
  (80, '6571253', array['+', '-', '×', '÷']::text[], 6, 8, 3),
  (81, '238', array['+', '-', '^', '×', '÷']::text[], 6, 8, 4),
  (82, '9431764', array['+', '-', '^', '×', '÷']::text[], 11, 16, 4),
  (83, '2112299', array['+', '-', '^', '×', '÷']::text[], 2, 4, 4),
  (84, '3173223', array['+', '-', '^', '×', '÷']::text[], 14, 21, 4),
  (85, '2544246', array['+', '-', '^', '×', '÷']::text[], 15, 22, 4),
  (86, '3136122', array['+', '-', '^', '×', '÷']::text[], 6, 9, 4),
  (87, '3137522', array['+', '-', '^', '×', '÷']::text[], 18, 27, 4),
  (88, '3129111', array['+', '-', '^', '×', '÷']::text[], 18, 27, 4),
  (89, '1543967', array['+', '-', '^', '×', '÷']::text[], 14, 20, 4),
  (90, '5451542', array['+', '-', '^', '×', '÷']::text[], 2, 4, 4),
  (91, '2297324', array['+', '-', '^', '×', '÷']::text[], 9, 13, 4),
  (92, '3222221', array['+', '-', '^', '×', '÷']::text[], 5, 7, 4),
  (93, '3499268', array['+', '-', '^', '×', '÷']::text[], 6, 9, 4),
  (94, '2267431', array['+', '-', '^', '×', '÷']::text[], 16, 24, 4),
  (95, '2414727', array['+', '-', '^', '×', '÷']::text[], 6, 8, 4),
  (96, '9725212', array['+', '-', '^', '×', '÷']::text[], 16, 23, 4),
  (97, '4489913', array['+', '-', '^', '×', '÷']::text[], 6, 8, 4),
  (98, '6555234', array['+', '-', '^', '×', '÷']::text[], 17, 25, 4),
  (99, '2141351', array['+', '-', '^', '×', '÷']::text[], 11, 16, 4),
  (100, '1221112', array['+', '-', '^', '×', '÷']::text[], 3, 5, 4),
  (101, '25124623', array['+', '-', '^', '×', '÷']::text[], 20, 29, 4),
  (102, '16321891', array['+', '-', '^', '×', '÷']::text[], 11, 16, 4),
  (103, '35535822', array['+', '-', '^', '×', '÷']::text[], 5, 7, 4),
  (104, '62361133', array['+', '-', '^', '×', '÷']::text[], 12, 18, 4),
  (105, '11383258', array['+', '-', '^', '×', '÷']::text[], 8, 12, 4),
  (106, '27732128', array['+', '-', '^', '×', '÷']::text[], 6, 8, 4),
  (107, '33841735', array['+', '-', '^', '×', '÷']::text[], 16, 23, 4),
  (108, '52435272', array['+', '-', '^', '×', '÷']::text[], 6, 9, 4),
  (109, '23641186', array['+', '-', '^', '×', '÷']::text[], 11, 16, 4),
  (110, '22112388', array['+', '-', '^', '×', '÷']::text[], 6, 8, 4),
  (111, '24216212', array['+', '-', '^', '×', '÷']::text[], 23, 34, 4),
  (112, '45452321', array['+', '-', '^', '×', '÷']::text[], 8, 11, 4),
  (113, '23218957', array['+', '-', '^', '×', '÷']::text[], 20, 29, 4),
  (114, '44311113', array['+', '-', '^', '×', '÷']::text[], 6, 8, 4),
  (115, '42835385', array['+', '-', '^', '×', '÷']::text[], 3, 5, 4),
  (116, '14121725', array['+', '-', '^', '×', '÷']::text[], 17, 25, 4),
  (117, '33245381', array['+', '-', '^', '×', '÷']::text[], 15, 22, 4),
  (118, '22242252', array['+', '-', '^', '×', '÷']::text[], 8, 12, 4),
  (119, '21139254', array['+', '-', '^', '×', '÷']::text[], 18, 27, 4),
  (120, '54625199', array['+', '-', '^', '×', '÷']::text[], 17, 25, 4),
  (121, '100012349', array['+', '-', '^', '×', '÷']::text[], 6, 8, 5),
  (122, '21941673', array['+', '-', '^', '×', '÷']::text[], 7, 10, 5),
  (123, '95181986', array['+', '-', '^', '×', '÷']::text[], 16, 24, 5),
  (124, '91121192', array['+', '-', '^', '×', '÷']::text[], 15, 22, 5),
  (125, '98223219', array['+', '-', '^', '×', '÷']::text[], 12, 18, 5),
  (126, '85253334', array['+', '-', '^', '×', '÷']::text[], 16, 23, 5),
  (127, '19877544', array['+', '-', '^', '×', '÷']::text[], 16, 24, 5),
  (128, '59591155', array['+', '-', '^', '×', '÷']::text[], 17, 25, 5),
  (129, '15932382', array['+', '-', '^', '×', '÷']::text[], 20, 30, 5),
  (130, '46625111', array['+', '-', '^', '×', '÷']::text[], 5, 7, 5),
  (131, '24539521', array['+', '-', '^', '×', '÷']::text[], 22, 33, 5),
  (132, '11765813', array['+', '-', '^', '×', '÷']::text[], 9, 13, 5),
  (133, '91233133', array['+', '-', '^', '×', '÷']::text[], 1, 3, 5),
  (134, '34629222', array['+', '-', '^', '×', '÷']::text[], 19, 28, 5),
  (135, '13113684', array['+', '-', '^', '×', '÷']::text[], 6, 9, 5),
  (136, '25451175', array['+', '-', '^', '×', '÷']::text[], 24, 35, 5),
  (137, '72375825', array['+', '-', '^', '×', '÷']::text[], 14, 21, 5),
  (138, '31123751', array['+', '-', '^', '×', '÷']::text[], 18, 27, 5),
  (139, '36517444', array['+', '-', '^', '×', '÷']::text[], 1, 3, 5),
  (140, '11324535', array['+', '-', '^', '×', '÷']::text[], 7, 10, 5),
  (141, '644411317', array['+', '-', '^', '×', '÷']::text[], 7, 10, 5),
  (142, '259932586', array['+', '-', '^', '×', '÷']::text[], 21, 31, 5),
  (143, '211293623', array['+', '-', '^', '×', '÷']::text[], 18, 27, 5),
  (144, '712433198', array['+', '-', '^', '×', '÷']::text[], 12, 17, 5),
  (145, '113112331', array['+', '-', '^', '×', '÷']::text[], 3, 5, 5),
  (146, '361214398', array['+', '-', '^', '×', '÷']::text[], 23, 34, 5),
  (147, '141561665', array['+', '-', '^', '×', '÷']::text[], 17, 25, 5),
  (148, '725766988', array['+', '-', '^', '×', '÷']::text[], 6, 8, 5),
  (149, '364185459', array['+', '-', '^', '×', '÷']::text[], 22, 33, 5),
  (150, '852521114', array['+', '-', '^', '×', '÷']::text[], 11, 16, 5),
  (151, '547792221', array['+', '-', '^', '×', '÷']::text[], 17, 25, 5),
  (152, '144417129', array['+', '-', '^', '×', '÷']::text[], 3, 5, 5),
  (153, '112498664', array['+', '-', '^', '×', '÷']::text[], 6, 8, 5),
  (154, '235495457', array['+', '-', '^', '×', '÷']::text[], 19, 28, 5),
  (155, '653314213', array['+', '-', '^', '×', '÷']::text[], 6, 9, 5),
  (156, '327331198', array['+', '-', '^', '×', '÷']::text[], 18, 27, 5),
  (157, '762173447', array['+', '-', '^', '×', '÷']::text[], 1, 3, 5),
  (158, '121473613', array['+', '-', '^', '×', '÷']::text[], 5, 7, 5),
  (159, '516272662', array['+', '-', '^', '×', '÷']::text[], 19, 28, 5),
  (160, '332115823', array['+', '-', '^', '×', '÷']::text[], 14, 21, 5),
  (161, '417386388', array['+', '-', '^', '×', '÷']::text[], 22, 33, 5),
  (162, '441221222', array['+', '-', '^', '×', '÷']::text[], 2, 4, 5),
  (163, '723214542', array['+', '-', '^', '×', '÷']::text[], 17, 25, 5),
  (164, '541217968', array['+', '-', '^', '×', '÷']::text[], 12, 18, 5),
  (165, '162363211', array['+', '-', '^', '×', '÷']::text[], 8, 11, 5),
  (166, '121212236', array['+', '-', '^', '×', '÷']::text[], 4, 6, 5),
  (167, '456633293', array['+', '-', '^', '×', '÷']::text[], 6, 9, 5),
  (168, '869895423', array['+', '-', '^', '×', '÷']::text[], 21, 31, 5),
  (169, '342117913', array['+', '-', '^', '×', '÷']::text[], 14, 21, 5),
  (170, '776833142', array['+', '-', '^', '×', '÷']::text[], 24, 35, 5),
  (171, '231221872', array['+', '-', '^', '×', '÷']::text[], 17, 25, 5),
  (172, '421147726', array['+', '-', '^', '×', '÷']::text[], 6, 8, 5),
  (173, '881292728', array['+', '-', '^', '×', '÷']::text[], 1, 3, 5),
  (174, '121151423', array['+', '-', '^', '×', '÷']::text[], 2, 4, 5),
  (175, '954814715', array['+', '-', '^', '×', '÷']::text[], 22, 33, 5),
  (176, '922941227', array['+', '-', '^', '×', '÷']::text[], 5, 7, 5),
  (177, '338478122', array['+', '-', '^', '×', '÷']::text[], 1, 3, 5),
  (178, '115559532', array['+', '-', '^', '×', '÷']::text[], 17, 25, 5),
  (179, '358864127', array['+', '-', '^', '×', '÷']::text[], 24, 35, 5),
  (180, '291333749', array['+', '-', '^', '×', '÷']::text[], 22, 33, 5),
  (181, '882422222', array['+', '-', '^', '×', '÷']::text[], 22, 32, 5),
  (182, '278422142', array['+', '-', '^', '×', '÷']::text[], 11, 16, 5),
  (183, '727313753', array['+', '-', '^', '×', '÷']::text[], 24, 35, 5),
  (184, '258364345', array['+', '-', '^', '×', '÷']::text[], 20, 29, 5),
  (185, '243241157', array['+', '-', '^', '×', '÷']::text[], 5, 7, 5),
  (186, '531425176', array['+', '-', '^', '×', '÷']::text[], 21, 31, 5),
  (187, '479722852', array['+', '-', '^', '×', '÷']::text[], 18, 26, 5),
  (188, '971231294', array['+', '-', '^', '×', '÷']::text[], 14, 21, 5),
  (189, '611396845', array['+', '-', '^', '×', '÷']::text[], 7, 10, 5),
  (190, '142213262', array['+', '-', '^', '×', '÷']::text[], 6, 8, 5),
  (191, '866371739', array['+', '-', '^', '×', '÷']::text[], 10, 14, 5),
  (192, '145794144', array['+', '-', '^', '×', '÷']::text[], 9, 13, 5),
  (193, '253813351', array['+', '-', '^', '×', '÷']::text[], 3, 5, 5),
  (194, '223377356', array['+', '-', '^', '×', '÷']::text[], 6, 9, 5),
  (195, '883242222', array['+', '-', '^', '×', '÷']::text[], 11, 16, 5),
  (196, '152733732', array['+', '-', '^', '×', '÷']::text[], 14, 21, 5),
  (197, '128334755', array['+', '-', '^', '×', '÷']::text[], 21, 31, 5),
  (198, '252645952', array['+', '-', '^', '×', '÷']::text[], 23, 34, 5),
  (199, '542472767', array['+', '-', '^', '×', '÷']::text[], 18, 26, 5),
  (200, '436898479', array['+', '-', '^', '×', '÷']::text[], 23, 34, 5)
on conflict (level_id) do update
set digit_string = excluded.digit_string,
    available_operators = excluded.available_operators,
    minimum_score = excluded.minimum_score,
    target_score = excluded.target_score,
    difficulty = excluded.difficulty,
    updated_at = now();
-- LEVEL_RULE_VALUES_END

create or replace function public._numbering_precedence(p_operator text)
returns integer
language sql
immutable
strict
set search_path = public
as $$
  select case
    when p_operator = '^' then 3
    when p_operator in ('×', '÷') then 2
    else 1
  end;
$$;

create or replace function public._numbering_apply_operator(
  p_left bigint,
  p_operator text,
  p_right bigint
)
returns bigint
language plpgsql
immutable
strict
set search_path = public
as $$
declare
  v_result bigint;
  v_factor bigint;
  v_exponent bigint;
begin
  case p_operator
    when '+' then v_result := p_left + p_right;
    when '-' then v_result := p_left - p_right;
    when '×' then v_result := p_left * p_right;
    when '÷' then
      if p_right = 0 then
        raise exception 'invalid expression: division by zero';
      end if;
      if p_left % p_right <> 0 then
        raise exception 'invalid expression: division must have an integer result';
      end if;
      v_result := p_left / p_right;
    when '^' then
      if p_right < 0 then
        raise exception 'invalid expression: exponent must be non-negative';
      end if;
      if p_left = 0 and p_right = 0 then
        raise exception 'invalid expression: zero to zero power';
      end if;
      v_result := 1;
      v_factor := p_left;
      v_exponent := p_right;
      while v_exponent > 0 loop
        if v_exponent % 2 = 1 then
          if v_factor <> 0
             and abs(v_result) > 999999999 / abs(v_factor) then
            raise exception 'invalid expression: result outside Numbering range';
          end if;
          v_result := v_result * v_factor;
        end if;
        v_exponent := v_exponent / 2;
        if v_exponent > 0 then
          if v_factor <> 0
             and abs(v_factor) > 999999999 / abs(v_factor) then
            raise exception 'invalid expression: result outside Numbering range';
          end if;
          v_factor := v_factor * v_factor;
        end if;
      end loop;
    else
      raise exception 'invalid expression: unknown operator';
  end case;
  if abs(v_result) > 999999999 then
    raise exception 'invalid expression: result outside Numbering range';
  end if;
  return v_result;
end;
$$;

create or replace function public._numbering_evaluate_expression(p_source text)
returns bigint
language plpgsql
immutable
strict
set search_path = public
as $$
declare
  v_values bigint[] := array[]::bigint[];
  v_operators text[] := array[]::text[];
  v_index integer := 1;
  v_length integer := char_length(p_source);
  v_character text;
  v_start integer;
  v_expects_operand boolean := true;
  v_left bigint;
  v_right bigint;
  v_operator text;
  v_count integer;
begin
  if v_length < 1 or v_length > 64
     or p_source !~ '^[0-9+\-×÷^()]+$' then
    raise exception 'invalid expression';
  end if;

  while v_index <= v_length loop
    v_character := substr(p_source, v_index, 1);
    if v_character ~ '^[0-9]$' then
      if not v_expects_operand then
        raise exception 'invalid expression: operator required';
      end if;
      v_start := v_index;
      while v_index <= v_length
        and substr(p_source, v_index, 1) ~ '^[0-9]$' loop
        v_index := v_index + 1;
      end loop;
      v_values := array_append(
        v_values,
        substr(p_source, v_start, v_index - v_start)::bigint
      );
      v_expects_operand := false;
      continue;
    elsif v_character = '(' then
      if not v_expects_operand then
        raise exception 'invalid expression: implicit multiplication';
      end if;
      v_operators := array_append(v_operators, v_character);
      v_index := v_index + 1;
      continue;
    elsif v_character = ')' then
      if v_expects_operand then
        raise exception 'invalid expression: empty parenthesis';
      end if;
      while coalesce(array_length(v_operators, 1), 0) > 0
        and v_operators[array_length(v_operators, 1)] <> '(' loop
        v_count := array_length(v_values, 1);
        if v_count < 2 then
          raise exception 'invalid expression: missing operand';
        end if;
        v_right := v_values[v_count];
        v_left := v_values[v_count - 1];
        v_values := coalesce(v_values[1:v_count - 2], array[]::bigint[]);
        v_count := array_length(v_operators, 1);
        v_operator := v_operators[v_count];
        v_operators := coalesce(v_operators[1:v_count - 1], array[]::text[]);
        v_values := array_append(
          v_values,
          public._numbering_apply_operator(v_left, v_operator, v_right)
        );
      end loop;
      v_count := coalesce(array_length(v_operators, 1), 0);
      if v_count = 0 then
        raise exception 'invalid expression: unmatched parenthesis';
      end if;
      v_operators := coalesce(v_operators[1:v_count - 1], array[]::text[]);
      v_expects_operand := false;
      v_index := v_index + 1;
      continue;
    elsif v_character in ('+', '-', '×', '÷', '^') then
      if v_expects_operand then
        raise exception 'invalid expression: unary operator';
      end if;
      while coalesce(array_length(v_operators, 1), 0) > 0
        and v_operators[array_length(v_operators, 1)] <> '('
        and (
          public._numbering_precedence(
            v_operators[array_length(v_operators, 1)]
          ) > public._numbering_precedence(v_character)
          or (
            public._numbering_precedence(
              v_operators[array_length(v_operators, 1)]
            ) = public._numbering_precedence(v_character)
            and v_character <> '^'
          )
        ) loop
        v_count := array_length(v_values, 1);
        if v_count < 2 then
          raise exception 'invalid expression: missing operand';
        end if;
        v_right := v_values[v_count];
        v_left := v_values[v_count - 1];
        v_values := coalesce(v_values[1:v_count - 2], array[]::bigint[]);
        v_count := array_length(v_operators, 1);
        v_operator := v_operators[v_count];
        v_operators := coalesce(v_operators[1:v_count - 1], array[]::text[]);
        v_values := array_append(
          v_values,
          public._numbering_apply_operator(v_left, v_operator, v_right)
        );
      end loop;
      v_operators := array_append(v_operators, v_character);
      v_expects_operand := true;
      v_index := v_index + 1;
      continue;
    end if;
    raise exception 'invalid expression';
  end loop;

  if v_expects_operand then
    raise exception 'invalid expression: trailing operator';
  end if;
  while coalesce(array_length(v_operators, 1), 0) > 0 loop
    v_count := array_length(v_operators, 1);
    v_operator := v_operators[v_count];
    if v_operator = '(' then
      raise exception 'invalid expression: unmatched parenthesis';
    end if;
    v_operators := coalesce(v_operators[1:v_count - 1], array[]::text[]);
    v_count := array_length(v_values, 1);
    if v_count < 2 then
      raise exception 'invalid expression: missing operand';
    end if;
    v_right := v_values[v_count];
    v_left := v_values[v_count - 1];
    v_values := coalesce(v_values[1:v_count - 2], array[]::bigint[]);
    v_values := array_append(
      v_values,
      public._numbering_apply_operator(v_left, v_operator, v_right)
    );
  end loop;
  if coalesce(array_length(v_values, 1), 0) <> 1 then
    raise exception 'invalid expression';
  end if;
  return v_values[1];
end;
$$;

-- Submission RPCs are redefined below so both normal and 12-hour daily
-- challenges accept the same exponent grammar as the client evaluator.

create or replace function public.submit_numbering_result(
  p_level_id integer,
  p_expression text,
  p_used_hints integer default 0
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_rule private.numbering_level_rules%rowtype;
  v_expression text := regexp_replace(
    replace(replace(btrim(p_expression), '*', '×'), '/', '÷'),
    '\s+', '', 'g'
  );
  v_sides text[];
  v_left bigint;
  v_right bigint;
  v_score integer;
  v_previous integer;
  v_current integer;
  v_weekly integer;
  v_rank integer;
  v_week_key text := to_char(timezone('Asia/Seoul', now()), 'IYYY-IW');
  v_operator text;
begin
  if v_user_id is null then raise exception 'authentication required'; end if;
  if not exists (select 1 from public.games where id = 'numbering') then
    raise exception 'invalid game';
  end if;
  if p_level_id is null or p_used_hints is null
     or p_used_hints not between 0 and 3 then
    raise exception 'invalid Numbering result';
  end if;
  select * into v_rule
  from private.numbering_level_rules
  where level_id = p_level_id;
  if not found then raise exception 'invalid Numbering stage'; end if;
  if v_expression is null or char_length(v_expression) > 96
     or v_expression !~ '^[0-9+\-×÷^=()]+$'
     or char_length(v_expression)
       - char_length(replace(v_expression, '=', '')) <> 1 then
    raise exception 'invalid Numbering expression';
  end if;
  if regexp_replace(v_expression, '[^0-9]', '', 'g')
     <> v_rule.digit_string then
    raise exception 'Numbering digits do not match the stage';
  end if;
  foreach v_operator in array array['+', '-', '×', '÷', '^'] loop
    if position(v_operator in v_expression) > 0
       and not (v_operator = any(v_rule.available_operators)) then
      raise exception 'operator is not available for this stage';
    end if;
  end loop;
  v_sides := string_to_array(v_expression, '=');
  if coalesce(v_sides[1], '') = '' or coalesce(v_sides[2], '') = '' then
    raise exception 'invalid Numbering equation';
  end if;
  v_left := public._numbering_evaluate_expression(v_sides[1]);
  v_right := public._numbering_evaluate_expression(v_sides[2]);
  if v_left <> v_right or v_left < v_rule.minimum_score
     or v_left > 999999999 then
    raise exception 'invalid Numbering result';
  end if;
  v_score := v_left::integer;

  perform pg_advisory_xact_lock(
    hashtextextended(v_user_id::text || ':numbering', 0)
  );
  select score into v_previous
  from public.scores
  where user_id = v_user_id and game_id = 'numbering';

  perform set_config('app.numbering_verified_write', 'on', true);
  insert into public.scores (user_id, game_id, score, stage)
  values (v_user_id, 'numbering', v_score, p_level_id)
  on conflict (user_id, game_id) do update
  set score = excluded.score,
      stage = excluded.stage,
      updated_at = timezone('utc', now())
  where excluded.score > public.scores.score;

  select score into v_current
  from public.scores
  where user_id = v_user_id and game_id = 'numbering';

  insert into public.weekly_scores (user_id, game_id, week_key, score)
  values (v_user_id, 'numbering', v_week_key, v_score)
  on conflict (user_id, game_id, week_key) do update
  set score = excluded.score,
      updated_at = timezone('utc', now())
  where excluded.score > public.weekly_scores.score;
  select score into v_weekly
  from public.weekly_scores
  where user_id = v_user_id and game_id = 'numbering'
    and week_key = v_week_key;

  select public.get_my_rank('numbering') into v_rank;
  return jsonb_build_object(
    'verified_score', v_score,
    'previous_best', v_previous,
    'current_best', v_current,
    'is_new_best', v_previous is null or v_score > v_previous,
    'verified_stage', p_level_id,
    'weekly_best', v_weekly,
    'rank', v_rank
  );
end;
$$;

create or replace function public.submit_numbering_daily_result(
  p_seed integer,
  p_expression text
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_period_key text := public._numbering_challenge_period_key(now());
  v_expected_seed integer;
  v_expected_digits text;
  v_expression text := regexp_replace(
    replace(replace(btrim(p_expression), '*', '×'), '/', '÷'),
    '\s+', '', 'g'
  );
  v_submitted_digits text;
  v_sides text[];
  v_left bigint;
  v_right bigint;
  v_score integer;
  v_digest text;
  v_existing_score integer;
  v_existing_seed integer;
  v_existing_digest text;
begin
  if v_user_id is null then raise exception 'authentication required'; end if;
  if not exists (select 1 from public.games where id = 'numbering') then
    raise exception 'invalid game';
  end if;
  v_expected_seed := public.get_daily_challenge_seed(
    'numbering', v_period_key
  );
  if p_seed is distinct from v_expected_seed then
    raise exception 'invalid daily seed';
  end if;
  if not exists (
    select 1 from public.daily_attempts
    where user_id = v_user_id and game_id = 'numbering'
      and date_key = v_period_key and seed = v_expected_seed
  ) then
    raise exception 'daily entry not claimed';
  end if;
  if v_expression is null or char_length(v_expression) > 96
     or v_expression !~ '^[0-9+\-×÷^=()]+$'
     or char_length(v_expression)
       - char_length(replace(v_expression, '=', '')) <> 1 then
    raise exception 'invalid daily expression';
  end if;

  v_expected_digits := public._numbering_daily_digits(v_expected_seed);
  v_submitted_digits := regexp_replace(v_expression, '[^0-9]', '', 'g');
  if public._numbering_sorted_digits(v_submitted_digits)
     <> public._numbering_sorted_digits(v_expected_digits) then
    raise exception 'daily expression digits do not match the seed';
  end if;

  v_sides := string_to_array(v_expression, '=');
  if coalesce(v_sides[1], '') = '' or coalesce(v_sides[2], '') = '' then
    raise exception 'invalid daily equation';
  end if;
  v_left := public._numbering_evaluate_expression(v_sides[1]);
  v_right := public._numbering_evaluate_expression(v_sides[2]);
  if v_left <> v_right or v_left < 0 or v_left > 99999999 then
    raise exception 'invalid daily score';
  end if;
  v_score := v_left::integer;
  v_digest := encode(digest(v_expression, 'sha256'), 'hex');

  perform pg_advisory_xact_lock(
    hashtextextended(v_user_id::text || ':numbering:' || v_period_key, 0)
  );
  select score, seed, summary_json ->> 'expression_sha256'
  into v_existing_score, v_existing_seed, v_existing_digest
  from public.daily_scores
  where user_id = v_user_id and game_id = 'numbering'
    and date_key = v_period_key;

  if found then
    if v_existing_seed is distinct from v_expected_seed
       or v_existing_score is distinct from v_score
       or v_existing_digest is distinct from v_digest then
      raise exception 'daily score already submitted';
    end if;
    return jsonb_build_object(
      'verified_score', v_existing_score,
      'previous_best', v_existing_score,
      'current_best', v_existing_score,
      'is_new_best', false,
      'is_idempotent', true,
      'date_key', v_period_key
    );
  end if;

  perform set_config('app.numbering_verified_write', 'on', true);
  insert into public.daily_scores (
    user_id, game_id, date_key, seed, score, replay_code, summary_json
  ) values (
    v_user_id,
    'numbering',
    v_period_key,
    v_expected_seed,
    v_score,
    null,
    jsonb_build_object(
      'version', 4,
      'expression_sha256', v_digest,
      'verified_digits', v_expected_digits,
      'submission_rule', 'reordered_equality_exponent_12h_entry'
    )
  );
  delete from public.numbering_daily_progress
  where user_id = v_user_id and period_key = v_period_key;

  return jsonb_build_object(
    'verified_score', v_score,
    'previous_best', null,
    'current_best', v_score,
    'is_new_best', true,
    'is_idempotent', false,
    'date_key', v_period_key
  );
end;
$$;

revoke all on function public._numbering_precedence(text)
from public, anon, authenticated;
revoke all on function public._numbering_apply_operator(bigint, text, bigint)
from public, anon, authenticated;
revoke all on function public._numbering_evaluate_expression(text)
from public, anon, authenticated;
revoke all on function public.submit_numbering_result(integer, text, integer)
from public, anon;
revoke all on function public.submit_numbering_daily_result(integer, text)
from public, anon;
grant execute on function public.submit_numbering_result(integer, text, integer)
to authenticated;
grant execute on function public.submit_numbering_daily_result(integer, text)
to authenticated;

notify pgrst, 'reload schema';
