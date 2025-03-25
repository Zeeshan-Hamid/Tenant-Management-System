//= require active_admin/base
// unit form
document.addEventListener("DOMContentLoaded", function () {
  const statusField = document.getElementById("unit_status");
  const rentalRateField = document.getElementById("rental_rate_field");
  const sellingRateField = document.getElementById("selling_rate_field");

  function toggleFields() {
      if (!statusField) return;

     
      const selectedStatus = parseInt(statusField.value, 10);

      
      const RENTAL_STATUS = 0;   // available_for_rent
      const SELLING_STATUS = 1;  // available_for_selling

      // Show/hide fields based on status
      rentalRateField.style.display = selectedStatus === RENTAL_STATUS ? "block" : "none";
      sellingRateField.style.display = selectedStatus === SELLING_STATUS ? "block" : "none";
  }

  if (statusField) {
      toggleFields(); // Initialize visibility on page load
      statusField.addEventListener("change", toggleFields); // Update on selection change
  }
});

// Role privelages auto checkbox
document.addEventListener("DOMContentLoaded", function() {
  var superAdminCheckbox = document.querySelector('#admin_user_super_admin');
  if (!superAdminCheckbox) return;

  var privilegeCheckboxes = document.querySelectorAll('input[name="admin_user[privileges][]"]');

  function updatePrivileges() {
    if (superAdminCheckbox.checked) {
      privilegeCheckboxes.forEach(function(cb) {
        cb.checked = true;
      });
    } else {
      privilegeCheckboxes.forEach(function(cb) {
        cb.checked = false;
      });
    }
  }

  superAdminCheckbox.addEventListener('change', updatePrivileges);
  // Initialize on page load to reflect the current state
  updatePrivileges();
});


// Lease Agreement Property and Unit Selector

document.addEventListener('DOMContentLoaded', function() {
  var propertyDropdownButton = document.getElementById('property-dropdown-button');
  var propertyDropdownContent = document.getElementById('property-dropdown-content');
  var propertySearchInput = document.querySelector('.property-search-input');
  var propertyItems = document.querySelectorAll('.properties-list .property-item');
  var selectedPropertySpan = document.querySelector('.selected-property');
  var propertyHiddenField = document.getElementById('property_selector_hidden');
  
  // Initialize property selection on edit
  if (propertyHiddenField && propertyHiddenField.value) {
    var propertyId = propertyHiddenField.value;
    var selectedProperty = document.querySelector(`.property-item[data-property-id="${propertyId}"]`);
    
    if (selectedProperty) {
      // Update dropdown button text
      selectedPropertySpan.textContent = selectedProperty.textContent.trim();
      
      // Show the corresponding property section
      document.querySelectorAll('.property-section').forEach(function(section) {
        section.style.display = section.getAttribute('data-property-id') === propertyId ? 'block' : 'none';
      });
    }
  }
  
  propertyDropdownButton.addEventListener('click', function(e) {
    e.preventDefault();
    e.stopPropagation();
    propertyDropdownContent.classList.toggle('visible');
    if(propertyDropdownContent.classList.contains('visible')) {
      propertySearchInput.focus();
    }
  });
  document.addEventListener('click', function(e) {
    if(!propertyDropdownContent.contains(e.target) && e.target !== propertyDropdownButton) {
      propertyDropdownContent.classList.remove('visible');
    }
  });
  propertySearchInput.addEventListener('input', function() {
    var query = this.value.toLowerCase();
    propertyItems.forEach(function(item) {
      var text = item.textContent.toLowerCase();
      item.style.display = text.includes(query) ? '' : 'none';
    });
  });
  propertyItems.forEach(function(item) {
    item.addEventListener('click', function() {
      var propertyId = this.getAttribute('data-property-id');
      var propertyName = this.textContent;
      selectedPropertySpan.textContent = propertyName;
      propertyHiddenField.value = propertyId;
      propertyDropdownContent.classList.remove('visible');
      var sections = document.querySelectorAll('.property-section');
      sections.forEach(function(section) {
        section.style.display = section.getAttribute('data-property-id') === propertyId ? 'block' : 'none';
      });
    });
  });
  document.querySelectorAll('.property-units-dropdown').forEach(function(dropdown) {
    var dropdownButton = dropdown.querySelector('.dropdown-button');
    var dropdownContent = dropdown.querySelector('.dropdown-content');
    var searchInput = dropdown.querySelector('.unit-search-input');
    var selectedCount = dropdown.querySelector('.selected-count');
    dropdownButton.addEventListener('click', function(e) {
      e.preventDefault();
      e.stopPropagation();
      dropdownContent.classList.toggle('visible');
      if(dropdownContent.classList.contains('visible')) {
        searchInput.focus();
      }
    });
    document.addEventListener('click', function(e) {
      if(!dropdown.contains(e.target)) {
        dropdownContent.classList.remove('visible');
      }
    });
    searchInput.addEventListener('input', function() {
      var query = this.value.toLowerCase();
      dropdown.querySelectorAll('.unit-item').forEach(function(item) {
        var text = item.querySelector('label').textContent.toLowerCase();
        item.style.display = text.includes(query) ? '' : 'none';
      });
    });
    dropdown.querySelectorAll('.unit-checkbox').forEach(function(checkbox) {
      checkbox.addEventListener('change', function() {
        var checked = dropdown.querySelectorAll('.unit-checkbox:checked').length;
        selectedCount.textContent = checked > 0 ? (checked + " unit" + (checked > 1 ? "s" : "") + " selected") : "Select units";
      });
    });
  });
});



//= require active_admin/base
// Property Selector

document.addEventListener('DOMContentLoaded', function() {
  document.querySelectorAll('.property-type-dropdown').forEach(function(dropdown) {
    const dropdownButton = dropdown.querySelector('.dropdown-button');
    const dropdownContent = dropdown.querySelector('.dropdown-content');
    const searchInput = dropdown.querySelector('.type-search-input');
    const typeItems = dropdown.querySelectorAll('.type-item');
    const selectedValueSpan = dropdown.querySelector('.selected-value');
    const hiddenInput = dropdown.querySelector('input[type="hidden"]');

    // Toggle dropdown visibility
    dropdownButton.addEventListener('click', function(e) {
      e.preventDefault();
      e.stopPropagation();
      dropdownContent.classList.toggle('visible');
      if (dropdownContent.classList.contains('visible')) {
        searchInput.focus();
      }
    });

    // Close dropdown when clicking outside
    document.addEventListener('click', function(e) {
      if (!dropdown.contains(e.target)) {
        dropdownContent.classList.remove('visible');
      }
    });

    // Search filter
    searchInput.addEventListener('input', function() {
      const query = this.value.toLowerCase();
      dropdown.querySelectorAll('.type-item').forEach(function(item) {
        const text = item.textContent.toLowerCase();
        item.style.display = text.includes(query) ? '' : 'none';
      });
    });

    // Single selection: clicking an item updates the hidden field and button label
    typeItems.forEach(function(item) {
      item.addEventListener('click', function() {
        const value = this.getAttribute('data-value');
        const text = this.textContent;
        selectedValueSpan.textContent = text;
        hiddenInput.value = value;
        dropdownContent.classList.remove('visible');
      });
    });
  });
});



// Users properties lease agreements selector
// admin_property_lease_selector.js

document.addEventListener('DOMContentLoaded', function() {
  initAdminPropertyLeaseSelector();
});

function initAdminPropertyLeaseSelector() {
  const selector = document.querySelector('.admin-property-lease-selector');
  if (!selector) return;
  
  initPropertyDropdown(selector);
  initLeaseDropdowns(selector);
  initLeaseTags(selector);
  
  // Initialize the first selected property if any
  const firstSelectedProperty = findFirstSelectedProperty(selector);
  if (firstSelectedProperty) {
    selectProperty(selector, firstSelectedProperty);
  }
}

function findFirstSelectedProperty(selector) {
  // Check if there are any properties with selected lease agreements
  const propertySections = selector.querySelectorAll('.apl-property-section');
  for (const section of propertySections) {
    const selectedLeases = section.querySelectorAll('.apl-lease-checkbox:checked');
    if (selectedLeases.length > 0) {
      return section.getAttribute('data-property-id');
    }
  }
  
  // If no properties have selected leases, return the first property
  const firstPropertyItem = selector.querySelector('.apl-property-item');
  return firstPropertyItem ? firstPropertyItem.getAttribute('data-property-id') : null;
}

function selectProperty(selector, propertyId) {
  const propertyItem = selector.querySelector(`.apl-property-item[data-property-id="${propertyId}"]`);
  if (!propertyItem) return;
  
  const selectedPropertySpan = selector.querySelector('.apl-selected-property');
  if (selectedPropertySpan) {
    selectedPropertySpan.textContent = propertyItem.textContent.trim();
  }
  
  // Show the corresponding property section
  selector.querySelectorAll('.apl-property-section').forEach(function(section) {
    section.style.display = section.getAttribute('data-property-id') === propertyId ? 'block' : 'none';
  });
}

function initPropertyDropdown(selector) {
  const propertyDropdownButton = selector.querySelector('#apl-property-dropdown-button');
  const propertyDropdownContent = selector.querySelector('#apl-property-dropdown-content');
  const propertySearchInput = selector.querySelector('.apl-property-search-input');
  const propertyItems = selector.querySelectorAll('.apl-properties-list .apl-property-item');
  const selectedPropertySpan = selector.querySelector('.apl-selected-property');
  
  if (!propertyDropdownButton) return;
  
  // Toggle dropdown visibility
  propertyDropdownButton.addEventListener('click', function(e) {
    e.preventDefault();
    e.stopPropagation();
    propertyDropdownContent.classList.toggle('visible');
    if (propertyDropdownContent.classList.contains('visible')) {
      propertySearchInput.focus();
    }
  });
  
  // Close dropdown when clicking outside
  document.addEventListener('click', function(e) {
    if (!propertyDropdownContent.contains(e.target) && e.target !== propertyDropdownButton) {
      propertyDropdownContent.classList.remove('visible');
    }
  });
  
  // Filter properties on search
  propertySearchInput.addEventListener('input', function() {
    const query = this.value.toLowerCase().trim();
    propertyItems.forEach(function(item) {
      const text = item.textContent.trim().toLowerCase();
      item.style.display = text.includes(query) ? '' : 'none';
    });
  });
  
  // Handle property selection
  propertyItems.forEach(function(item) {
    item.addEventListener('click', function() {
      const propertyId = this.getAttribute('data-property-id');
      const propertyName = this.textContent.trim();
      
      // Update UI
      selectedPropertySpan.textContent = propertyName;
      propertyDropdownContent.classList.remove('visible');
      
      // Show/hide property sections
      selector.querySelectorAll('.apl-property-section').forEach(function(section) {
        section.style.display = section.getAttribute('data-property-id') === propertyId ? 'block' : 'none';
      });
    });
  });
}

function initLeaseDropdowns(selector) {
  selector.querySelectorAll('.apl-lease-dropdown').forEach(function(dropdown) {
    const dropdownButton = dropdown.querySelector('.apl-dropdown-button');
    const dropdownContent = dropdown.querySelector('.apl-dropdown-content');
    const searchInput = dropdown.querySelector('.apl-lease-search-input');
    const selectedCount = dropdown.querySelector('.apl-selected-count');
    const selectedLeasesContainer = dropdown.querySelector('.apl-selected-leases');
    const propertySection = dropdown.closest('.apl-property-section');
    const propertyId = propertySection ? propertySection.getAttribute('data-property-id') : null;
    
    // Toggle dropdown visibility
    dropdownButton.addEventListener('click', function(e) {
      e.preventDefault();
      e.stopPropagation();
      dropdownContent.classList.toggle('visible');
      if (dropdownContent.classList.contains('visible')) {
        searchInput.focus();
      }
    });
    
    // Close dropdown when clicking outside
    document.addEventListener('click', function(e) {
      if (!dropdown.contains(e.target)) {
        dropdownContent.classList.remove('visible');
      }
    });
    
    // Filter lease agreements on search
    searchInput.addEventListener('input', function() {
      const query = this.value.toLowerCase().trim();
      dropdown.querySelectorAll('.apl-lease-item').forEach(function(item) {
        const text = item.querySelector('label').textContent.trim().toLowerCase();
        item.style.display = text.includes(query) ? '' : 'none';
      });
    });
    
    // Handle lease agreement selection
    dropdown.querySelectorAll('.apl-lease-checkbox').forEach(function(checkbox) {
      checkbox.addEventListener('change', function() {
        const leaseId = this.value;
        const leaseText = this.nextElementSibling.textContent.trim();
        const isChecked = this.checked;
        
        // Update selected count
        const checkedCount = dropdown.querySelectorAll('.apl-lease-checkbox:checked').length;
        selectedCount.textContent = checkedCount > 0 
          ? `${checkedCount} lease agreement${checkedCount > 1 ? 's' : ''} selected` 
          : "Select lease agreements";
        
        // Update destroy flag based on selection
        updateDestroyFlag(propertySection, checkedCount === 0);
        
        // Update selected lease tags
        if (isChecked) {
          // Add tag if not exists
          if (!selectedLeasesContainer.querySelector(`[data-lease-id="${leaseId}"]`)) {
            // Create a simplified version of the text for the tag
            const unitsPart = leaseText.substring(leaseText.indexOf('Units:'));
            const tagText = `Lease #${leaseId} - ${unitsPart}`;
            
            const tag = document.createElement('div');
            tag.className = 'apl-selected-lease-tag';
            tag.setAttribute('data-lease-id', leaseId);
            tag.innerHTML = `
              ${tagText}
              <span class="apl-remove-lease" data-lease-id="${leaseId}">×</span>
            `;
            selectedLeasesContainer.appendChild(tag);
            
            // Add click handler to the remove button
            tag.querySelector('.apl-remove-lease').addEventListener('click', function() {
              checkbox.checked = false;
              checkbox.dispatchEvent(new Event('change', { bubbles: true }));
            });
          }
        } else {
          // Remove tag if exists
          const existingTag = selectedLeasesContainer.querySelector(`[data-lease-id="${leaseId}"]`);
          if (existingTag) {
            existingTag.remove();
          }
        }
      });
    });
  });
}

// Function to update the destroy flag and display message
function updateDestroyFlag(propertySection, shouldDestroy) {
  if (!propertySection) return;
  
  const destroyFlag = propertySection.querySelector('.destroy-property-flag');
  const statusMessage = propertySection.querySelector('.apl-status-message');
  const propertyActions = propertySection.querySelector('.apl-property-actions');
  
  if (!propertyActions) return;
  
  if (shouldDestroy) {
    // Create elements if they don't exist
    if (!destroyFlag) {
      const propertyId = propertySection.getAttribute('data-property-id');
      const hiddenInput = document.createElement('input');
      hiddenInput.type = 'hidden';
      hiddenInput.name = `user[user_properties_attributes][${propertyId}][_destroy]`;
      hiddenInput.value = '1';
      hiddenInput.id = `user_user_properties_attributes_${propertyId}_destroy`;
      hiddenInput.className = 'destroy-property-flag';
      propertyActions.appendChild(hiddenInput);
    }
    
    if (!statusMessage) {
      const message = document.createElement('p');
      message.className = 'apl-status-message';
      message.textContent = 'This property will be removed when saving';
      propertyActions.appendChild(message);
    }
  } else {
    // Remove elements if they exist
    if (destroyFlag) {
      destroyFlag.remove();
    }
    
    if (statusMessage) {
      statusMessage.remove();
    }
  }
}

function initLeaseTags(selector) {
  // Initial setup of remove buttons on pre-existing tags
  selector.querySelectorAll('.apl-remove-lease').forEach(function(removeButton) {
    const leaseId = removeButton.getAttribute('data-lease-id');
    removeButton.addEventListener('click', function() {
      const checkbox = selector.querySelector(`input[value="${leaseId}"]`);
      if (checkbox) {
        checkbox.checked = false;
        checkbox.dispatchEvent(new Event('change', { bubbles: true }));
      }
      const tag = this.closest('.apl-selected-lease-tag');
      if (tag) {
        tag.remove();
      }
    });
  });
}