# frozen_string_literal: true

require "test_helper"
require "json"
BIN_AUDIT = File.expand_path("../../bin/rbs-audit", __dir__)
load BIN_AUDIT

class RBS::AuditTest < Test::Unit::TestCase

  def run_audit(*args)
    cmd = [RbConfig.ruby, BIN_AUDIT, *args]
    stdout, stderr, status = Open3.capture3(*cmd)
    [stdout.force_encoding(Encoding::UTF_8), stderr.force_encoding(Encoding::UTF_8), status]
  end

  def test_help
    stdout, _stderr, status = run_audit("--help")
    assert_predicate status, :success?
    assert_include stdout, "Usage: bin/rbs-audit"
  end

  def test_audit_base64_json
    stdout, _stderr, status = run_audit("base64", "-f", "json")
    assert_predicate status, :success?

    data = JSON.parse(stdout)
    assert_equal "base64", data["library"]
    assert_equal 1, data["gap_modules"]
    assert_include data["modules"]["Base64"]["missing_constants"], "VERSION"
  end

  def test_audit_base64_markdown
    stdout, _stderr, status = run_audit("base64", "-f", "markdown")
    assert_predicate status, :success?

    assert_include stdout, "# RBS Audit Report: `base64`"
    assert_include stdout, "| `Base64` | ⚠️ Incomplete | Constants: `VERSION` |"
  end

  def test_audit_base64_strict_fails
    _stdout, _stderr, status = run_audit("base64", "--strict")
    assert_not_predicate status, :success?
  end

  def test_audit_uri
    stdout, _stderr, status = run_audit("uri", "-f", "json")
    assert_predicate status, :success?

    data = JSON.parse(stdout)
    assert_equal "uri", data["library"]
    assert_instance_of Hash, data["modules"]
  end

  def test_rbs_auditor_instance
    out = StringIO.new
    auditor = RBSAuditor.new("base64", { format: "json", verbose: false }, out: out)
    assert_equal "base64", auditor.library
    assert_equal false, auditor.run # fails because base64 has missing constants
    assert_include out.string, "missing_constants"
  end
end
