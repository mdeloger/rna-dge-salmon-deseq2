"""
This rule prepares DESeq2 output for further use with IGR GSEA shiny portal
"""
rule deseq2_to_gseaapp:
    input:
        tsv = "deseq2/{design}/TSV/Deseq2_{factor}.tsv",
        tx2gene = "tximport/transcript_to_gene_id_to_gene_name.tsv"
    output:
        complete = "GSEA/{design}/{factor}.complete.tsv",
        fc_fc = "GSEA/{design}/{factor}.filtered_on_padj_and_fc.stat_change_is_fold_change.tsv",
        padj_fc = "GSEA/{design}/{factor}.filtered_on_padj.stat_change_is_padj.tsv"
    message:
        "Subsetting DESeq2 results for {wildcards.factor} ({wildcards.factor})"
    threads:
        1
    resources:
        mem_mb = (
            lambda wildcards, attempt: min(attempt * 2048, 10240)
        ),
        time_min = (
            lambda wildcards, attempt: min(attempt * 40, 200)
        )
    log:
        "logs/deseq2_to_gseaapp/{design}/{factor}.log"
    wrapper:
        f"{git}/bio/pandas/deseq2_to_gseaapp"


"""
Subsets the tr2gene table in order to enhance the gseapp table
"""
rule subset_tr2gene:
    input:
        "tximport/transcript_to_gene_id_to_gene_name.tsv"
    output:
        "tximport/gene2gene.tsv"
    message:
        "Building Gene to Gene conversion table"
    threads:
        1
    resources:
        mem_mb = (
            lambda wildcards, attempt: min(attempt * 2048, 10240)
        ),
        time_min = (
            lambda wildcards, attempt: min(attempt * 40, 200)
        )
    log:
        "logs/gseaapp_filter/gene2gene.log"
    shell:
        "awk 'BEGIN{{FS=\"\\t\"}} NR != 1 {{print $1\"\\t\"$3}}' "
        " {input} "
        " | sort "
        " | uniq "
        " > {output} "
        " 2> {log}"


"""
This rule clarifies the results of deseq2 in order to include gene names and
identifiers
"""
rule gseapp_clarify_complete:
    input:
        tsv = "GSEA/{design}/{factor}.complete.tsv",
        tx2gene = "tximport/gene2gene.tsv"
    output:
        tsv = report(
            "GSEA/{design}/{factor}.complete.tsv",
            caption="../report/gseapp_complete.rst",
            category="DGE Results"
        )
    message:
        "Making GSEAapp human readable ({wildcards.design}/{wildcards.factor})"
        " considering complete results"
    threads:
        1
    resources:
        mem_mb = (
            lambda wildcards, attempt: min(attempt * 2048, 10240)
        ),
        time_min = (
            lambda wildcards, attempt: min(attempt * 40, 200)
        )
    params:
        header = None,
        genes = True,
        index = True
    log:
        "logs/gseaapp_filter/{design}/{factor}/complete.log"
    wrapper:
        f"{git}/bio/pandas/add_genes"


rule gseapp_clarify_fc_fc:
    input:
        tsv = "GSEA/{design}/{factor}.filtered_on_padj_and_fc.stat_change_is_fold_change.tsv",
        tx2gene = "tximport/gene2gene.tsv"
    output:
        tsv = report(
            "GSEA/{design}/{factor}.fc_fc.tsv",
            caption="../report/gseapp_fc_fc.rst",
            category="GSEAapp Shiny"
        )
    message:
        "Making GSEAapp human readable ({wildcards.design}/{wildcards.factor})"
        " considering fold change."
    threads:
        1
    resources:
        mem_mb = (
            lambda wildcards, attempt: min(attempt * 2048, 10240)
        ),
        time_min = (
            lambda wildcards, attempt: min(attempt * 40, 200)
        )
    params:
        header = None,
        genes = True,
        index = True
    log:
        "logs/gseaapp_filter/{design}/{factor}/fc_fc.log"
    wrapper:
        f"{git}/bio/pandas/add_genes"


rule gseapp_clarify_padj_fc:
    input:
        tsv = "GSEA/{design}/{factor}.filtered_on_padj.stat_change_is_padj.tsv",
        tx2gene = "tximport/gene2gene.tsv"
    output:
        tsv = report(
            "GSEA/{design}/{factor}.padj_fc.tsv",
            category="GSEAapp Shiny",
            caption="../report/gseapp_padj_fc.rst"
        )
    message:
        "Making GSEAapp human readable ({wildcards.design}/{wildcards.factor})"
        " considering both foldchange and padj."
    threads:
        1
    resources:
        mem_mb = (
            lambda wildcards, attempt: min(attempt * 2048, 10240)
        ),
        time_min = (
            lambda wildcards, attempt: min(attempt * 40, 200)
        )
    params:
        header = None,
        genes = True,
        index = True
    log:
        "logs/gseaapp_filter/{design}/{factor}/padj_fc.log"
    wrapper:
        f"{git}/bio/pandas/add_genes"


rule zip_gsea:
    input:
        htmls = lambda wildcards: gsea_tsv(wildcards)
    output:
        "GSEA/gsea.{design}.tar.bz2"
    message:
        "Tar bzipping all GSEAapp tables for {wildcards.design}"
    threads:
        1
    resources:
        mem_mb = (
            lambda wildcards, attempt: min(attempt * 1024, 10240)
        ),
        time_min = (
            lambda wildcards, attempt: min(attempt * 20, 200)
        )
    conda:
        "../envs/bash.yaml"
    log:
        "logs/figures_archive/gsea_{design}.log"
    shell:
        "tar -cvjf {output} {input.htmls} > {log} 2>&1"
