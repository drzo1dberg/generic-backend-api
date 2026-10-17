INFRA ?= infra/local
DB    := databases
TF    := terraform

# Verbindungsdaten aus dem Infra-Modul an das Datenbank-Modul durchreichen.
db_env = \
	TF_VAR_pg_host=$$($(TF) -chdir=$(INFRA) output -raw host) \
	TF_VAR_pg_port=$$($(TF) -chdir=$(INFRA) output -raw port) \
	TF_VAR_pg_admin_user=$$($(TF) -chdir=$(INFRA) output -raw admin_user) \
	TF_VAR_pg_admin_password=$$($(TF) -chdir=$(INFRA) output -raw admin_password)

CONTAINER = $$($(TF) -chdir=$(INFRA) output -raw container_name)
ADMIN     = $$($(TF) -chdir=$(INFRA) output -raw admin_user)

.PHONY: up down init plan psql fmt sql

init:
	$(TF) -chdir=$(INFRA) init -input=false
	$(TF) -chdir=$(DB) init -input=false

up: init
	$(TF) -chdir=$(INFRA) apply -auto-approve -input=false
	$(db_env) $(TF) -chdir=$(DB) apply -auto-approve -input=false

# Muss nach "up" "No changes" melden (Idempotenz).
plan:
	$(TF) -chdir=$(INFRA) plan -detailed-exitcode -input=false
	$(db_env) $(TF) -chdir=$(DB) plan -detailed-exitcode -input=false

# Datenbank-State zuerst wegwerfen: der Container (und damit alles darin) verschwindet ohnehin.
down:
	rm -f $(DB)/terraform.tfstate $(DB)/terraform.tfstate.backup
	$(TF) -chdir=$(INFRA) destroy -auto-approve -input=false

# make psql            -> Admin auf Datenbank postgres
# make psql DB_NAME=gehalt
DB_NAME ?= postgres
psql:
	docker exec -it $(CONTAINER) psql -U $(ADMIN) -d $(DB_NAME)

fmt:
	$(TF) fmt -recursive

# Spielt sql/<db>/*.sql in Dateinamen-Reihenfolge ein, jeweils als <db>_owner
# (damit die Default Privileges greifen). Nur auf frischer Instanz: nicht idempotent.
# Ersetzt in Schritt 8 durch ein echtes Migrationstool.
sql:
	@for dir in sql/*/; do \
	  db=$$(basename $$dir); \
	  for f in $$dir*.sql; do \
	    [ -e "$$f" ] || continue; \
	    echo "==> $$f (als $${db}_owner)"; \
	    docker exec -i -e PGOPTIONS="-c role=$${db}_owner" $(CONTAINER) \
	      psql -U $(ADMIN) -d $$db -v ON_ERROR_STOP=1 -q -f - < $$f || exit 1; \
	  done; \
	done
