(function () {
  const form = document.getElementById('support-form');
  const statusEl = document.getElementById('form-status');
  const submitButton = document.getElementById('submit-button');

  function setStatus(message, type) {
    statusEl.textContent = message;
    statusEl.className = type ? 'status ' + type : 'status';
  }

  function value(id) {
    return document.getElementById(id).value.trim();
  }

  form.addEventListener('submit', async function (event) {
    event.preventDefault();
    setStatus('', '');

    const topic = value('topic');
    const message = value('message');
    const contact = value('contact');

    if (message.length < 10) {
      setStatus('Please enter at least 10 characters.', 'error');
      return;
    }

    submitButton.disabled = true;
    submitButton.textContent = 'Submitting...';

    try {
      await firebase.database().ref('support_requests').push({
        topic: topic,
        message: message,
        contact: contact,
        source: 'experts_hosting_support',
        pageUrl: window.location.href.slice(0, 500),
        referrer: document.referrer.slice(0, 500),
        userAgent: navigator.userAgent.slice(0, 512),
        status: 'new',
        createdAt: firebase.database.ServerValue.TIMESTAMP
      });

      form.reset();
      setStatus('Support request submitted. Thank you.', 'success');
    } catch (error) {
      console.error(error);
      setStatus(
        'The request could not be submitted. Please try again later.',
        'error'
      );
    } finally {
      submitButton.disabled = false;
      submitButton.textContent = 'Submit Support Request';
    }
  });
})();
