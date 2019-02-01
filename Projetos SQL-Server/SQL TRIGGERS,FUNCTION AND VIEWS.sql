CREATE VIEW vwVisao1
AS
 select st.ID, st.name, st.tot_cred, dep.dept_name AS "DEPARTMENT NAME" FROM student st
 JOIN department dep on dep.dept_name = st.dept_name
 WHERE st.tot_cred >= 50 AND st.dept_name = 'Biology'
GO


CREATE TRIGGER Insercao_vwVisao1 
ON vwVisao1
INSTEAD OF INSERT
AS	
BEGIN 	  
   INSERT INTO student(ID, name, tot_cred, dept_name) SELECT id, name, tot_cred, [DEPARTMENT NAME] FROM inserted 
END
GO

DROP TRIGGER Insercao_vwVisao1 
--Teste de inserção na VIEW vwVisao1
insert into vwVisao1 values(00127,'Alexandre', 120, 'Biology');
insert into vwVisao1 values(00450,'Paulo', 56, 'Biology');
insert into vwVisao1 values(00820,'Carlos', 78, 'Biology');
insert into vwVisao1 values(14850,'Richard', 99, 'Biology');
--Teste em que essa inserção o Aluno tem o tot_cred abaixo de 50 logo ele não deve aparecer na View.
insert into vwVisao1 values(14859,'Colombo', 45, 'Biology');



CREATE TRIGGER delete_vwVisao1
ON vwVisao1
INSTEAD OF DELETE
AS
BEGIN
   DELETE vwVisao1  where  name in (SELECT name from deleted);     
END;
GO
--Teste de Exclusão do Estudante da VIEW vwVisao1 
delete from vwVisao1 where name = 'Richard';

CREATE TRIGGER update_vwVisao1
ON vwVisao1
INSTEAD OF UPDATE
AS
  BEGIN
     IF(UPDATE(ID))
	 BEGIN
	    RAISERROR ('ID não pode ser modificado',16,1)
	    RETURN
     END

	 IF(UPDATE([DEPARTMENT NAME]))
	 BEGIN
	    RAISERROR ('[DEPARTMENT NAME] não pode ser modificado',16,1)
	    RETURN
     END
	 
	 IF(UPDATE(name))
	 BEGIN
	    DECLARE @NAME varchar(20), @ID INT;
        
		SELECT @ID = st.ID FROM student st JOIN inserted ON inserted.ID = st.ID
		IF(@ID IS NULL)
		BEGIN
		  RAISERROR ('Aluno Inexistente!',16,1)
	      RETURN
		END
		SELECT @NAME = inserted.name FROM inserted
		UPDATE student set name = @NAME FROM inserted JOIN student 
                                                ON student.ID = inserted.ID
     END
  END
GO

SELECT * from vwVisao1
DELETE FROM student where name = 'Alexandre'

--Alterando o nome do Aluno pelo ID 
UPDATE vwVisao1 set name = 'Alexandre Pinheiro'
WHERE ID = 127;  

--Validação da não alteração do ID
UPDATE vwVisao1 set ID = 15945
WHERE ID = 127;

--Validação da não alteração do [DEPARTMENT NAME]
UPDATE vwVisao1 set [DEPARTMENT NAME] = 'Biology5'
WHERE ID = 127;

----------------------------------------------------------
--Usuários e autorizações:
CREATE LOGIN usuario1 
    WITH PASSWORD = 'usuario1';
GO
CREATE USER usuario1 FOR LOGIN usuario1;
GO

GRANT INSERT, UPDATE, DELETE ON student   to usuario1
GRANT INSERT, UPDATE, DELETE ON department  to usuario1
GRANT INSERT, UPDATE, DELETE ON course to usuario1
GRANT SELECT ON student to usuario1
GRANT SELECT ON department to usuario1
GRANT SELECT ON course to usuario1

-- Revogando a permissão EXECUTE para usuario1
USE [TB UNIVERSIDADE];
REVOKE EXECUTE to usuario1
GO

CREATE LOGIN usuario2 
    WITH PASSWORD = 'usuario2';
GO
CREATE USER usuario2 FOR LOGIN usuario2;
GO

GRANT SELECT ON dbo.vwVisao1  to usuario2
GRANT SELECT ON dbo.vwVisao2  to usuario2
GRANT SELECT ON dbo.vwVisao3  to usuario2

--Esse Comando REVOKE remove a permissão de SELECT a vwVisao1 do Uusuario 2 
REVOKE SELECT ON OBJECT:: vwVisao1 FROM usuario2;  


CREATE LOGIN usuario3 
    WITH PASSWORD = 'usuario3';
GO
CREATE USER usuario3 FOR LOGIN usuario3;
GO
--Permissões de procedimento armazenado
GRANT EXECUTE to usuario3

--------------------------------------------------------------

--delete from department where building is null

insert into course values ('BIO-101', 'Intro. to Biology', 'Biology', '4');
insert into course values ('BIO-301', 'Genetics', 'Biology', '4');
insert into course values ('BIO-399', 'Computational Biology', 'Biology', '3');
insert into course values ('CS-101', 'Intro. to Computer Science', 'Comp. Sci.', '4');
insert into course values ('CS-190', 'Game Design', 'Comp. Sci.', '4');
insert into course values ('CS-315', 'Robotics', 'Comp. Sci.', '3');
insert into course values ('CS-319', 'Image Processing', 'Comp. Sci.', '3');
insert into course values ('CS-347', 'Database System Concepts', 'Comp. Sci.', '3');
insert into course values ('EE-181', 'Intro. to Digital Systems', 'Elec. Eng.', '3');
insert into course values ('FIN-201', 'Investment Banking', 'Finance', '3');
insert into course values ('HIS-351', 'World History', 'History', '3');
insert into course values ('MU-199', 'Music Video Production', 'Music', '3');
insert into course values ('PHY-101', 'Physical Principles', 'Physics', '4');
insert into instructor values ('10101', 'Srinivasan', 'Comp. Sci.', '65000');

Select * from department

CREATE VIEW vwVisao2
AS 
Select c.course_id, c.dept_name from course c
JOIN department dep ON dep.dept_name = c.dept_name
WHERE c.credits = 3 AND dep.building = 'Taylor'
GROUP BY c.course_id, c.dept_name
GO

SELECT * from vwVisao2
SELECT * from department
SELECT * from course

CREATE TRIGGER Insercao_vwVisao2 
ON vwVisao2
INSTEAD OF INSERT
AS	
BEGIN
    DECLARE
      @DEPT_NAME varchar(20), @COURSE_ID varchar(8);
	  SELECT @DEPT_NAME = dbo.fn_Insert_Department_dept_name(i.dept_name)from inserted i;
	   IF(@DEPT_NAME IS NOT NULL)
	      BEGIN
	        INSERT INTO department(dept_name, building) SELECT @DEPT_NAME, 'Taylor' FROM inserted
		  END  	  
   
     IF(@DEPT_NAME is null)
      BEGIN
	        RAISERROR ('Department inserido já existe na tabela Department que é chave primária!',16,1)
	        RETURN
      END
   
      BEGIN
	     SELECT @COURSE_ID = dbo.fn_Insert_Course_course_id(i.course_id)from inserted i;
		  IF(@COURSE_ID IS NOT NULL)
		  BEGIN
             INSERT INTO course(course_id, dept_name, credits) SELECT course_id, dept_name, 3 FROM inserted
		  END	
		  
		  IF(@COURSE_ID is null)
          BEGIN
	         RAISERROR ('ID do Curso existente !',16,1)
--Como foi inserido um ID existente em course deve-se desfazer a inserção em Department
			 DELETE FROM department where dept_name = @DEPT_NAME;
	         RETURN
          END  
      END	    
END
GO
DROP TRIGGER Insercao_vwVisao2

CREATE FUNCTION fn_Insert_Department_dept_name(@DEPT_NAME varchar(20))
RETURNS varchar(20)
BEGIN
    IF((Select dept_name from department WHERE dept_name = @DEPT_NAME) IS NULL)
	   BEGIN
	     RETURN @DEPT_NAME
       END
    ELSE
	   SET @DEPT_NAME = NULL
	   RETURN @DEPT_NAME 
END

CREATE FUNCTION fn_Insert_Course_course_id (@COURSE_ID varchar(8))
RETURNS varchar(8)
BEGIN
    IF((Select course_id from course WHERE course_id = @COURSE_ID) IS NULL)
	   BEGIN
	     RETURN @COURSE_ID
       END
    ELSE
	   SET @COURSE_ID = NULL
	   RETURN @COURSE_ID 
END

drop FUNCTION fnc_Insert_Department_dept_name

select * from department
select * from course

Select * from vwVisao2


Delete from department where dept_name = 'Mathematics-1A';

--Inserindo valores na visão vwVisao2
INSERT INTO vwVisao2 VALUES ('MAT-101', 'Mathematics');
--Teste de inserção de valor na tabela Department já existente
INSERT INTO vwVisao2 VALUES ('MAT-102', 'Mathematics');
--Teste de inserção de valor na tabela Course já existente
INSERT INTO vwVisao2 VALUES ('MAT-101', 'Mathematics-1A');

-------------------------------DELETE NA vwVisao2--------------------------------------
GO

select * from vwVisao2
CREATE TRIGGER delete_vwVisao2
ON vwVisao2
INSTEAD OF DELETE
AS
BEGIN
   DECLARE  @COURSE_ID varchar(8);
	SELECT @COURSE_ID = dbo.fn_validar_couse_id_FOR_DELETE(i.course_id)  FROM deleted i;

	IF(@COURSE_ID IS NULL )
	 BEGIN
	    RAISERROR ('ID do curso inexistentes!', 16, 1)
		RETURN
     END
	ELSE
	  DELETE department  WHERE  dept_name  in (SELECT dept_name from deleted);  
	  DELETE course WHERE  course_id  in (SELECT course_id from deleted);     
END;
GO

DROP TRIGGER delete_vwVisao2

CREATE FUNCTION fn_validar_couse_id_FOR_DELETE(@COUSE_ID varchar (8))
RETURNS varchar(8)
BEGIN
    IF((SELECT course_id FROM course WHERE course_id = @COUSE_ID) IS NOT NULL)
	   BEGIN
	     RETURN @COUSE_ID
       END
    ELSE
	   SET @COUSE_ID = NULL
	   RETURN @COUSE_ID 
END 

drop function dbo.fn_validar_couse_id_FOR_DELETE
---Testando a validação tentando deletar um ID do curso inexistente.
delete from vwVisao2 where course_id = 'PPP-222';
---Testando a validação tentando deletar um ID do curso existente.
delete from vwVisao2 where course_id = 'MAT-101';


-------------------------------UPDATE NA vwVisao2--------------------------------------

CREATE TRIGGER update_vwVisao2
ON vwVisao2
INSTEAD OF UPDATE
AS
  BEGIN
   DECLARE @DEPT_NAME varchar(20), @COURSE_ID varchar(8); 
	
   IF UPDATE(course_id)
	BEGIN
	 SELECT @DEPT_NAME = dep.dept_name FROM department dep
	 JOIN inserted ON inserted.dept_name = dep.dept_name

	 IF(@DEPT_NAME IS NULL)
      BEGIN
	   RAISERROR('Nome do departamento informado inexistente!',16,1)
	   RETURN
      END
     ELSE
	   SELECT @COURSE_ID = inserted.course_id FROM inserted

	   UPDATE course set course_id = @COURSE_ID FROM inserted JOIN course 
                                                ON course.dept_name = inserted.dept_name     
     END
	    
   END	 
GO
DROp TRIGGER update_vwVisao2

--Testando a alteração no ID do Curso
UPDATE vwVisao2 set course_id ='MAT-107'
WHERE dept_name = 'Mathematics';  
--Testando a alteração em um departamento inexistente
UPDATE vwVisao2 set course_id ='MAT-102'
WHERE dept_name = 'Mathematics-A2';  

select * from vwVisao2
select * from department

select * from course
