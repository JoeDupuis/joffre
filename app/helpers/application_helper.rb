module ApplicationHelper
  def flash_message(type, message)
    message_type = type == "notice" ? "success" : "danger"

    tag.div(
      message,
      class: "flash-alert -#{message_type}",
      role: "alert",
      data: {
        controller: "alert",
        close_btn_class: "closeBtn"
      }
    )
  end
end
